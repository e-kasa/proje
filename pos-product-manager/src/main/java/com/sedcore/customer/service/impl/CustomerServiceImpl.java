package com.sedcore.customer.service.impl;

import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.common.enums.CustomerType;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.finance.entity.Payment;
import com.sedcore.common.enums.PaymentType;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.customer.model.CustomerAccountResponse;
import com.sedcore.customer.model.CustomerPaymentDto;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.finance.service.AccountAuditService;
import com.sedcore.finance.service.AccountTransactionService;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.finance.service.PaymentService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Slf4j
@Transactional
public class CustomerServiceImpl
        extends BaseDbServiceImp<CustomerRepository, Customer>
        implements CustomerService {

    @Autowired
    private CustomerAccountService customerAccountService;

    @Autowired
    private AccountTransactionService accountTransactionService;

    @Autowired
    @Lazy
    private PaymentService paymentService;

    @Autowired
    private AccountAuditService accountAuditService;

    @Override
    public Class<?> getDTOClassForService() {
        return Customer.class;
    }

    @Override
    @Transactional(readOnly = true)
    public Customer getEntity(String id) {
        return findById(id)
                .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + id));
    }

    // =========================================================================
    // CARİ HESAP İŞLEMLERİ
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public CustomerAccountResponse getCustomerAccount(String customerId) {
        log.info("Musteri cari hesap getiriliyor: id={}", customerId);
        return customerAccountService.getAccountResponse(customerId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getCustomerTransactions(String customerId) {
        log.info("Musteri hareketleri getiriliyor: id={}", customerId);
        return accountTransactionService.getByCustomer(customerId);
    }

    /**
     * Müşteriden tahsilat kaydı.
     *
     * Akış:
     *   1. Customer ve CustomerAccount'u yükle / oluştur
     *   2. CustomerAccountService.applyCredit() → bakiyeyi güncelle ve kaydet
     *   3. Payment entity'yi paymentService.savePayment() ile kaydet
     *   4. AccountTransaction kaydet — savedPayment.id ile bağla
     *   5. Payment'a accountTransactionId ata ve tekrar kaydet
     */
    @Override
    public CustomerAccountResponse recordPayment(String customerId, CustomerPaymentDto dto) {
        log.info("Musteri tahsilati kaydediliyor: customerId={}, amount={}", customerId, dto.getAmount());

        Customer customer = findById(customerId)
                .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + customerId));

        PaymentType paymentType = dto.getPaymentType() != null ? dto.getPaymentType() : PaymentType.CASH;
        String description = dto.getDescription() != null
                ? dto.getDescription()
                : "Musteri tahsilati - " + paymentType.getDescription();

        // 1. CustomerAccount bakiyesini güncelle
        CustomerAccount savedAcct = customerAccountService.applyCredit(customer, dto.getAmount());

        // 2. Payment entity kaydet
        Payment payment = Payment.builder()
                .customer(customer)
                .paymentType(paymentType)
                .amount(dto.getAmount())
                .paymentDate(LocalDateTime.now())
                .referenceNumber(dto.getReferenceNumber())
                .bankName(dto.getBankName())
                .description(description)
                .isCancelled(false)
                .isVerified(false)
                .build();
        Payment savedPayment = paymentService.savePayment(payment);

        // 3. AccountTransaction kaydet
        AccountTransaction tx = AccountTransaction.builder()
                .customer(customer)
                .payment(savedPayment)
                .transactionType(TransactionType.COLLECTION)
                .debitAmount(BigDecimal.ZERO)
                .creditAmount(dto.getAmount())
                .balance(savedAcct.getCurrentBalance())
                .referenceId(savedPayment.getId())
                .referenceType("PAYMENT")
                .referenceNumber(dto.getReferenceNumber())
                .description(description)
                .transactionDate(LocalDateTime.now())
                .isOverdue(false)
                .isCancelled(false)
                .build();
        AccountTransaction savedTx = accountTransactionService.save(tx);

        // 4. Payment'a accountTransactionId ata
        savedPayment.setAccountTransactionId(savedTx.getId());
        paymentService.savePayment(savedPayment);

        log.info("Musteri tahsilati tamamlandi: customerId={}, paymentId={}, yeniBakiye={}",
                customerId, savedPayment.getId(), savedAcct.getCurrentBalance());

        return customerAccountService.getAccountResponse(customerId);
    }

    @Override
    public CustomerAccountResponse updateCreditLimit(String customerId, BigDecimal newLimit) {
        log.info("Kredi limiti guncelleniyor: customerId={}, newLimit={}", customerId, newLimit);

        Customer customer = findById(customerId)
                .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + customerId));
        BigDecimal oldLimit = customer.getCreditLimit();
        customer.setCreditLimit(newLimit);
        save(customer);

        // Sprint 30 — issue P2.6: kredi limiti değişikliği audit kaydı
        accountAuditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, customerId, "creditLimit",
                oldLimit, newLimit, null);

        return customerAccountService.recalculate(customerId);
    }

    @Override
    public List<Customer> search(String search, Boolean isActive) {
        return dao.findBysearch(search, isActive);
    }

    @Override
    public long countByIsActive(Boolean aTrue) {
        return dao.countByIsActive(aTrue);
    }

    @Override
    public long countByCustomerType(CustomerType customerType) {
        return dao.countByCustomerType(customerType);
    }
}
