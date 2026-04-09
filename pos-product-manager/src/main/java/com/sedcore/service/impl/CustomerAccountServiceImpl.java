package com.sedcore.service.impl;

import com.sedcore.entity.Customer;
import com.sedcore.entity.CustomerAccount;
import com.sedcore.model.CustomerAccountResponse;
import com.sedcore.repository.CustomerAccountRepository;
import com.sedcore.repository.CustomerRepository;
import com.sedcore.service.CustomerAccountService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@Slf4j
@Transactional
public class CustomerAccountServiceImpl
        extends BaseDbServiceImp<CustomerAccountRepository, CustomerAccount>
        implements CustomerAccountService {

    @Autowired
    private CustomerRepository customerRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return CustomerAccountResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private CustomerAccountResponse mapToResponse(CustomerAccount acct) {
        return CustomerAccountResponse.builder()
                .id(acct.getId())
                .customerId(acct.getCustomer().getId())
                .customerName(acct.getCustomer().getName())
                .creditLimit(acct.getCustomer().getCreditLimit())
                .currentBalance(acct.getCurrentBalance())
                .totalDebt(acct.getTotalDebt())
                .totalCredit(acct.getTotalCredit())
                .overdueAmount(acct.getOverdueAmount())
                .availableCreditLimit(acct.getAvailableCreditLimit())
                .isCreditLimitExceeded(acct.getIsCreditLimitExceeded())
                .totalTransactionCount(acct.getTotalTransactionCount())
                .lastTransactionDate(acct.getLastTransactionDate())
                .lastPaymentDate(acct.getLastPaymentDate())
                .lastSaleDate(acct.getLastSaleDate())
                .build();
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
                .orElseThrow(() -> new RuntimeException("Musteri cari hesabi bulunamadi: " + customerId));
        return mapToResponse(acct);
    }

    @Override
    public CustomerAccountResponse recalculate(String customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + customerId));
        CustomerAccount acct = getOrCreate(customer);
        acct.updateCalculatedFields();
        return mapToResponse(save(acct));
    }
}
