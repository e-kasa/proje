package com.sedcore.service.impl;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.entity.Customer;
import com.sedcore.entity.CustomerAccount;
import com.sedcore.entity.Payment;
import com.sedcore.enums.PaymentType;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.AccountTransactionResponse;
import com.sedcore.model.CustomerAccountResponse;
import com.sedcore.model.CustomerPaymentDto;
import com.sedcore.repository.CustomerRepository;
import com.sedcore.service.AccountTransactionService;
import com.sedcore.service.CustomerAccountService;
import com.sedcore.service.CustomerService;
import com.sedcore.service.PaymentService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
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
        customer.setCreditLimit(newLimit);
        save(customer);

        return customerAccountService.recalculate(customerId);
    }
}
