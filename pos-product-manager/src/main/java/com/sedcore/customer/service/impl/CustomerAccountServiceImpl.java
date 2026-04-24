package com.sedcore.customer.service.impl;

import com.sedcore.common.config.MetricsConfiguration;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.model.CustomerAccountResponse;
import com.sedcore.customer.repository.CustomerAccountRepository;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.sedcore.finance.service.ReconcileAuditService;
import com.towpen.base.security.BaseDbServiceImp;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.sedcore.common.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class CustomerAccountServiceImpl
        extends BaseDbServiceImp<CustomerAccountRepository, CustomerAccount>
        implements CustomerAccountService {

    private final CustomerRepository customerRepository;
    private final AccountTransactionRepository accountTransactionRepository;
    private final ReconcileAuditService reconcileAuditService;
    private final MeterRegistry meterRegistry;

    @Override
    public Class<?> getDTOClassForService() {
        return CustomerAccountResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private CustomerAccountResponse mapToResponse(CustomerAccount acct) {
        CustomerAccountResponse dto = toDTO(acct);
        // Customer FK ilişkisinden gelen alanlar — BeanUtils doğrudan kopyalamaz
        if (acct.getCustomer() != null) {
            dto.setCustomerId(acct.getCustomer().getId());
            dto.setCustomerName(acct.getCustomer().getName());
            dto.setCreditLimit(acct.getCustomer().getCreditLimit());
        }
        return dto;
    }

    // =========================================================================
    // TEMEL İŞLEMLER
    // =========================================================================

    @Override
    public CustomerAccount getOrCreate(Customer customer) {
        return dao.findByCustomerId(customer.getId())
                .orElseGet(() -> {
                    log.info("Musteri hesabi olusturuluyor: customerId={}", customer.getId());
                    return save(CustomerAccount.builder()
                            .customer(customer)
                            .currentBalance(BigDecimal.ZERO)
                            .totalDebt(BigDecimal.ZERO)
                            .totalCredit(BigDecimal.ZERO)
                            .overdueAmount(BigDecimal.ZERO)
                            .totalTransactionCount(0L)
                            .build());
                });
    }

    // =========================================================================
    // BAKİYE İŞLEMLERİ
    // =========================================================================

    /** Müşteriden tahsilat: bakiye ↓, totalCredit ↑ */
    @Override
    public CustomerAccount applyCredit(Customer customer, BigDecimal amount) {
        CustomerAccount acct = getOrCreate(customer);
        acct.setCurrentBalance(acct.getCurrentBalance().subtract(amount));
        acct.setTotalCredit(acct.getTotalCredit().add(amount));
        acct.setLastPaymentDate(LocalDateTime.now());
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Musteri kredi uygulandi: customerId={}, amount={}, yeniBakiye={}",
                customer.getId(), amount, acct.getCurrentBalance());
        return save(acct);
    }

    /** Müşteriye satış: bakiye ↑, totalDebt ↑ */
    @Override
    public CustomerAccount applyDebit(Customer customer, BigDecimal amount) {
        CustomerAccount acct = getOrCreate(customer);
        acct.setCurrentBalance(acct.getCurrentBalance().add(amount));
        acct.setTotalDebt(acct.getTotalDebt().add(amount));
        acct.setLastSaleDate(LocalDateTime.now());
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Musteri borc uygulandi: customerId={}, amount={}, yeniBakiye={}",
                customer.getId(), amount, acct.getCurrentBalance());
        return save(acct);
    }

    /** Tahsilat iptali: bakiye ↑, totalCredit ↓ */
    @Override
    public CustomerAccount reverseCredit(Customer customer, BigDecimal amount) {
        CustomerAccount acct = getOrCreate(customer);
        acct.setCurrentBalance(acct.getCurrentBalance().add(amount));
        acct.setTotalCredit(acct.getTotalCredit().subtract(amount));
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Musteri kredi ters kayit: customerId={}, amount={}",
                customer.getId(), amount);
        return save(acct);
    }

    @Override
    @Transactional(readOnly = true)
    public CustomerAccountResponse getAccountResponse(String customerId) {
        CustomerAccount acct = dao.findByCustomerId(customerId)
                .orElseThrow(() -> new NotFoundException("CustomerAccount", customerId));
        return mapToResponse(acct);
    }

    @Override
    public CustomerAccountResponse recalculate(String customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new NotFoundException("Customer", customerId));
        CustomerAccount acct = getOrCreate(customer);
        acct.updateCalculatedFields();
        return mapToResponse(save(acct));
    }

    // =========================================================================
    // DRIFT RECONCILIATION
    // =========================================================================

    @Override
    public BigDecimal reconcile(String customerId) {
        long start = System.nanoTime();
        String status = MetricsConfiguration.STATUS_OK;
        try {
            Customer customer = customerRepository.findById(customerId)
                    .orElseThrow(() -> new NotFoundException("Customer", customerId));
            CustomerAccount acct = getOrCreate(customer);

            Object[] totals = accountTransactionRepository.ledgerTotalsForCustomer(customerId);
            BigDecimal ledgerBalance = (BigDecimal) totals[0];
            BigDecimal ledgerDebt = (BigDecimal) totals[1];
            BigDecimal ledgerCredit = (BigDecimal) totals[2];
            Long ledgerCount = (Long) totals[3];
            BigDecimal ledgerOverdue = (BigDecimal) totals[4];

            BigDecimal previousBalance = acct.getCurrentBalance();
            BigDecimal previousDebt = acct.getTotalDebt();
            BigDecimal previousCredit = acct.getTotalCredit();
            BigDecimal previousOverdue = acct.getOverdueAmount() != null
                    ? acct.getOverdueAmount() : BigDecimal.ZERO;
            BigDecimal drift = previousBalance.subtract(ledgerBalance);

            boolean changed = drift.compareTo(BigDecimal.ZERO) != 0
                    || previousDebt.compareTo(ledgerDebt) != 0
                    || previousCredit.compareTo(ledgerCredit) != 0
                    || previousOverdue.compareTo(ledgerOverdue) != 0;

            if (changed) {
                status = MetricsConfiguration.STATUS_DRIFT;
                log.warn("Musteri bakiye drift tespit edildi: customerId={}, denorm={}, ledger={}, drift={}, overdueDrift={}",
                        customerId, previousBalance, ledgerBalance, drift,
                        previousOverdue.subtract(ledgerOverdue));
                acct.setCurrentBalance(ledgerBalance);
                acct.setTotalDebt(ledgerDebt);
                acct.setTotalCredit(ledgerCredit);
                acct.setTotalTransactionCount(ledgerCount != null ? ledgerCount : 0L);
                acct.setOverdueAmount(ledgerOverdue);
                acct.updateCalculatedFields();
                save(acct);

                meterRegistry.counter(MetricsConfiguration.RECONCILE_DRIFT,
                        MetricsConfiguration.TAG_ENTITY_TYPE, "CUSTOMER").increment();
            }

            // Audit: her reconcile çağrısı (drift olsun olmasın) kayıt altına alınır — "ne zaman kontrol edildi" trail'i.
            reconcileAuditService.recordSingle(
                    ReconcileEntityType.CUSTOMER, customerId,
                    previousBalance, changed ? ledgerBalance : previousBalance,
                    previousDebt, changed ? ledgerDebt : previousDebt,
                    previousCredit, changed ? ledgerCredit : previousCredit,
                    drift);

            return drift;
        } catch (RuntimeException e) {
            status = MetricsConfiguration.STATUS_ERROR;
            throw e;
        } finally {
            meterRegistry.counter(MetricsConfiguration.RECONCILE_RUNS,
                    MetricsConfiguration.TAG_ENTITY_TYPE, "CUSTOMER",
                    MetricsConfiguration.TAG_SCOPE, "SINGLE",
                    MetricsConfiguration.TAG_STATUS, status).increment();
            Timer.builder(MetricsConfiguration.RECONCILE_DURATION)
                    .tag(MetricsConfiguration.TAG_ENTITY_TYPE, "CUSTOMER")
                    .tag(MetricsConfiguration.TAG_SCOPE, "SINGLE")
                    .register(meterRegistry)
                    .record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
    }

    @Override
    public int reconcileAll() {
        long start = System.nanoTime();
        String status = MetricsConfiguration.STATUS_OK;
        try {
            List<CustomerAccount> accounts = (List<CustomerAccount>) dao.findAll();
            int corrected = 0;
            for (CustomerAccount acct : accounts) {
                if (acct.getCustomer() == null) continue;
                BigDecimal drift = reconcile(acct.getCustomer().getId());
                if (drift.compareTo(BigDecimal.ZERO) != 0) corrected++;
            }
            if (corrected > 0) status = MetricsConfiguration.STATUS_DRIFT;
            log.info("Musteri reconcile tamamlandi: incelenen={}, duzeltilen={}", accounts.size(), corrected);
            reconcileAuditService.recordSweep(ReconcileEntityType.CUSTOMER, corrected);
            return corrected;
        } catch (RuntimeException e) {
            status = MetricsConfiguration.STATUS_ERROR;
            throw e;
        } finally {
            meterRegistry.counter(MetricsConfiguration.RECONCILE_RUNS,
                    MetricsConfiguration.TAG_ENTITY_TYPE, "CUSTOMER",
                    MetricsConfiguration.TAG_SCOPE, "ALL",
                    MetricsConfiguration.TAG_STATUS, status).increment();
            Timer.builder(MetricsConfiguration.RECONCILE_DURATION)
                    .tag(MetricsConfiguration.TAG_ENTITY_TYPE, "CUSTOMER")
                    .tag(MetricsConfiguration.TAG_SCOPE, "ALL")
                    .register(meterRegistry)
                    .record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
    }
}
