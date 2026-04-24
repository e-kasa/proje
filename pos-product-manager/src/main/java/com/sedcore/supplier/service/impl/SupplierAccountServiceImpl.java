package com.sedcore.supplier.service.impl;

import com.sedcore.common.config.MetricsConfiguration;
import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.sedcore.finance.service.AccountTransactionService;
import com.sedcore.finance.service.ReconcileAuditService;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.supplier.model.SupplierAccountResponse;
import com.sedcore.supplier.repository.SupplierAccountRepository;
import com.sedcore.supplier.repository.SupplierRepository;
import com.sedcore.supplier.service.SupplierAccountService;
import com.towpen.base.security.BaseDbServiceImp;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
@Transactional
public class SupplierAccountServiceImpl
        extends BaseDbServiceImp<SupplierAccountRepository, SupplierAccount>
        implements SupplierAccountService {

    // SupplierRepository aynı domain (tedarikçi) içinde olduğundan doğrudan inject edilir.
    @Autowired
    private SupplierRepository supplierRepository;

    @Autowired
    private AccountTransactionService accountTransactionRepository;

    @Autowired
    private ReconcileAuditService reconcileAuditService;

    @Autowired
    private MeterRegistry meterRegistry;

    @Override
    public Class<?> getDTOClassForService() {
        return SupplierAccountResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private SupplierAccountResponse mapToResponse(SupplierAccount acct) {
        SupplierAccountResponse dto = toDTO(acct);
        // Supplier FK ilişkisinden gelen alanlar — BeanUtils doğrudan kopyalamaz
        if (acct.getSupplier() != null) {
            dto.setSupplierId(acct.getSupplier().getId());
            dto.setSupplierName(acct.getSupplier().getName());
            dto.setCreditLimit(acct.getSupplier().getCreditLimit());
        }
        return dto;
    }

    // =========================================================================
    // TEMEL İŞLEMLER
    // =========================================================================

    @Override
    public SupplierAccount getOrCreate(Supplier supplier) {
        return dao.findBySupplierId(supplier.getId())
                .orElseGet(() -> {
                    log.info("Tedarikci hesabi olusturuluyor: supplierId={}", supplier.getId());
                    return save(SupplierAccount.builder()
                            .supplier(supplier)
                            .currentBalance(BigDecimal.ZERO)
                            .totalDebt(BigDecimal.ZERO)
                            .totalCredit(BigDecimal.ZERO)
                            .overdueAmount(BigDecimal.ZERO)
                            .totalTransactionCount(0L)
                            .build());
                });
    }

    @Override
    @Transactional(readOnly = true)
    public SupplierAccountResponse getAccountResponse(String supplierId) {
        SupplierAccount acct = dao.findBySupplierId(supplierId)
                .orElseThrow(() -> new RuntimeException("Tedarikci cari hesabi bulunamadi: " + supplierId));
        return mapToResponse(acct);
    }

    // =========================================================================
    // BAKİYE İŞLEMLERİ
    // =========================================================================

    /** Tedarikçiye ödeme: bakiye ↓, totalCredit ↑ */
    @Override
    public SupplierAccount applyCredit(Supplier supplier, BigDecimal amount) {
        SupplierAccount acct = getOrCreate(supplier);
        acct.setCurrentBalance(acct.getCurrentBalance().subtract(amount));
        acct.setTotalCredit(acct.getTotalCredit().add(amount));
        acct.setLastPaymentDate(LocalDateTime.now());
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Tedarikci kredi uygulandi: supplierId={}, amount={}, yeniBakiye={}",
                supplier.getId(), amount, acct.getCurrentBalance());
        return save(acct);
    }

    /** Tedarikçiden alım: bakiye ↑, totalDebt ↑ */
    @Override
    public SupplierAccount applyDebit(Supplier supplier, BigDecimal amount) {
        SupplierAccount acct = getOrCreate(supplier);
        acct.setCurrentBalance(acct.getCurrentBalance().add(amount));
        acct.setTotalDebt(acct.getTotalDebt().add(amount));
        acct.setLastPurchaseDate(LocalDateTime.now());
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Tedarikci borc uygulandi: supplierId={}, amount={}, yeniBakiye={}",
                supplier.getId(), amount, acct.getCurrentBalance());
        return save(acct);
    }

    /** Ödeme iptali: bakiye ↑, totalCredit ↓ */
    @Override
    public SupplierAccount reverseCredit(Supplier supplier, BigDecimal amount) {
        SupplierAccount acct = getOrCreate(supplier);
        acct.setCurrentBalance(acct.getCurrentBalance().add(amount));
        acct.setTotalCredit(acct.getTotalCredit().subtract(amount));
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Tedarikci kredi ters kayit: supplierId={}, amount={}",
                supplier.getId(), amount);
        return save(acct);
    }

    /** Satın alma iptali: bakiye ↓, totalDebt ↓ */
    @Override
    public SupplierAccount reverseDebit(Supplier supplier, BigDecimal amount) {
        SupplierAccount acct = getOrCreate(supplier);
        acct.setCurrentBalance(acct.getCurrentBalance().subtract(amount));
        acct.setTotalDebt(acct.getTotalDebt().subtract(amount));
        acct.setLastTransactionDate(LocalDateTime.now());
        acct.setTotalTransactionCount(acct.getTotalTransactionCount() + 1);
        acct.updateCalculatedFields();
        log.info("Tedarikci borc ters kayit: supplierId={}, amount={}",
                supplier.getId(), amount);
        return save(acct);
    }

    /** Kredi limiti değişince hesaplanan alanları güncelle */
    @Override
    public SupplierAccountResponse recalculate(String supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + supplierId));
        SupplierAccount acct = getOrCreate(supplier);
        acct.updateCalculatedFields();
        return mapToResponse(save(acct));
    }

    // =========================================================================
    // DRIFT RECONCILIATION
    // =========================================================================

    @Override
    public BigDecimal reconcile(String supplierId) {
        long start = System.nanoTime();
        String status = MetricsConfiguration.STATUS_OK;
        try {
            Supplier supplier = supplierRepository.findById(supplierId)
                    .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + supplierId));
            SupplierAccount acct = getOrCreate(supplier);

            Object[] totals = accountTransactionRepository.ledgerTotalsForSupplier(supplierId);
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
                log.warn("Tedarikci bakiye drift tespit edildi: supplierId={}, denorm={}, ledger={}, drift={}, overdueDrift={}",
                        supplierId, previousBalance, ledgerBalance, drift,
                        previousOverdue.subtract(ledgerOverdue));
                acct.setCurrentBalance(ledgerBalance);
                acct.setTotalDebt(ledgerDebt);
                acct.setTotalCredit(ledgerCredit);
                acct.setTotalTransactionCount(ledgerCount != null ? ledgerCount : 0L);
                acct.setOverdueAmount(ledgerOverdue);
                acct.updateCalculatedFields();
                save(acct);

                meterRegistry.counter(MetricsConfiguration.RECONCILE_DRIFT,
                        MetricsConfiguration.TAG_ENTITY_TYPE, "SUPPLIER").increment();
            }

            reconcileAuditService.recordSingle(
                    ReconcileEntityType.SUPPLIER, supplierId,
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
                    MetricsConfiguration.TAG_ENTITY_TYPE, "SUPPLIER",
                    MetricsConfiguration.TAG_SCOPE, "SINGLE",
                    MetricsConfiguration.TAG_STATUS, status).increment();
            Timer.builder(MetricsConfiguration.RECONCILE_DURATION)
                    .tag(MetricsConfiguration.TAG_ENTITY_TYPE, "SUPPLIER")
                    .tag(MetricsConfiguration.TAG_SCOPE, "SINGLE")
                    .register(meterRegistry)
                    .record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public int reconcileAll() {
        long start = System.nanoTime();
        String status = MetricsConfiguration.STATUS_OK;
        try {
            List<SupplierAccount> accounts = (List<SupplierAccount>) dao.findAll();
            int corrected = 0;
            for (SupplierAccount acct : accounts) {
                if (acct.getSupplier() == null) continue;
                BigDecimal drift = reconcile(acct.getSupplier().getId());
                if (drift.compareTo(BigDecimal.ZERO) != 0) corrected++;
            }
            if (corrected > 0) status = MetricsConfiguration.STATUS_DRIFT;
            log.info("Tedarikci reconcile tamamlandi: incelenen={}, duzeltilen={}", accounts.size(), corrected);
            reconcileAuditService.recordSweep(ReconcileEntityType.SUPPLIER, corrected);
            return corrected;
        } catch (RuntimeException e) {
            status = MetricsConfiguration.STATUS_ERROR;
            throw e;
        } finally {
            meterRegistry.counter(MetricsConfiguration.RECONCILE_RUNS,
                    MetricsConfiguration.TAG_ENTITY_TYPE, "SUPPLIER",
                    MetricsConfiguration.TAG_SCOPE, "ALL",
                    MetricsConfiguration.TAG_STATUS, status).increment();
            Timer.builder(MetricsConfiguration.RECONCILE_DURATION)
                    .tag(MetricsConfiguration.TAG_ENTITY_TYPE, "SUPPLIER")
                    .tag(MetricsConfiguration.TAG_SCOPE, "ALL")
                    .register(meterRegistry)
                    .record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
    }
}
