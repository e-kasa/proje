package com.sedcore.service.impl;

import com.sedcore.entity.*;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.PaymentRequest;
import com.sedcore.model.PaymentResponse;
import com.sedcore.repository.PaymentRepository;
import com.sedcore.service.*;
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

/**
 * Payment Service — Ödeme işlemleri
 *
 * Tüm repository erişimleri ilgili servisler üzerinden yapılır.
 * Kendi domain reposu (PaymentRepository) BaseDbServiceImp içinde.
 *
 * @Lazy SupplierService — SupplierServiceImpl de PaymentService inject ettiğinden
 *                         döngüsel bağımlılığı kırmak için gerekli.
 */
@Service
@Slf4j
@Transactional
public class PaymentServiceImpl
        extends BaseDbServiceImp<PaymentRepository, Payment>
        implements PaymentService {

    @Autowired
    private CustomerService customerService;

    @Autowired
    private CustomerAccountService customerAccountService;

    @Autowired
    @Lazy
    private SupplierService supplierService;

    @Autowired
    private SupplierAccountService supplierAccountService;

    @Autowired
    private SaleService saleService;

    @Autowired
    private PurchaseService purchaseService;

    @Autowired
    private AccountTransactionService accountTransactionService;

    @Override
    public Class<?> getDTOClassForService() {
        return PaymentResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private PaymentResponse mapToResponse(Payment p) {
        PaymentResponse.PaymentResponseBuilder builder = PaymentResponse.builder()
                .id(p.getId())
                .paymentType(p.getPaymentType())
                .paymentTypeLabel(p.getPaymentType() != null ? p.getPaymentType().getDescription() : null)
                .amount(p.getAmount())
                .paymentDate(p.getPaymentDate())
                .referenceNumber(p.getReferenceNumber())
                .bankName(p.getBankName())
                .accountNumber(p.getAccountNumber())
                .checkNumber(p.getCheckNumber())
                .checkDate(p.getCheckDate())
                .description(p.getDescription())
                .notes(p.getNotes())
                .accountTransactionId(p.getAccountTransactionId())
                .isCancelled(p.getIsCancelled())
                .cancelledDate(p.getCancelledDate())
                .cancelledReason(p.getCancelledReason())
                .isVerified(p.getIsVerified())
                .verifiedDate(p.getVerifiedDate())
                .verifiedBy(p.getVerifiedBy());

        if (p.getCustomer() != null) {
            builder.customerId(p.getCustomer().getId())
                   .customerName(p.getCustomer().getName());
        }
        if (p.getSupplier() != null) {
            builder.supplierId(p.getSupplier().getId())
                   .supplierName(p.getSupplier().getName());
        }
        if (p.getSale() != null) builder.saleId(p.getSale().getId());
        if (p.getPurchase() != null) builder.purchaseId(p.getPurchase().getId());

        return builder.build();
    }

    // =========================================================================
    // ÖDEME OLUŞTURMA
    // =========================================================================

    @Override
    public PaymentResponse createPayment(PaymentRequest request) {
        validate(request);

        Payment.PaymentBuilder paymentBuilder = Payment.builder()
                .paymentType(request.getPaymentType())
                .amount(request.getAmount())
                .paymentDate(request.getPaymentDate() != null ? request.getPaymentDate() : LocalDateTime.now())
                .referenceNumber(request.getReferenceNumber())
                .bankName(request.getBankName())
                .accountNumber(request.getAccountNumber())
                .checkNumber(request.getCheckNumber())
                .checkDate(request.getCheckDate())
                .description(request.getDescription())
                .notes(request.getNotes())
                .isCancelled(false)
                .isVerified(false);

        if (request.getSaleId() != null) {
            paymentBuilder.sale(saleService.getEntity(request.getSaleId()));
        }
        if (request.getPurchaseId() != null) {
            paymentBuilder.purchase(purchaseService.findById(request.getPurchaseId())
                    .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " + request.getPurchaseId())));
        }

        Payment payment = (request.getCustomerId() != null)
                ? createCustomerPayment(request, paymentBuilder)
                : createSupplierPayment(request, paymentBuilder);

        log.info("Odeme olusturuldu: id={}, tutar={}, tip={}",
                payment.getId(), payment.getAmount(), payment.getPaymentType());
        return mapToResponse(payment);
    }

    /** Müşteriden tahsilat: CustomerAccountService üzerinden bakiye güncelle */
    private Payment createCustomerPayment(PaymentRequest request, Payment.PaymentBuilder builder) {
        Customer customer = customerService.getEntity(request.getCustomerId());
        builder.customer(customer);
        Payment payment = save(builder.build());

        CustomerAccount savedAcct = customerAccountService.applyCredit(customer, request.getAmount());

        AccountTransaction tx = buildTransaction(
                null, customer, payment,
                TransactionType.COLLECTION,
                BigDecimal.ZERO, request.getAmount(),
                savedAcct.getCurrentBalance(),
                request.getReferenceNumber(),
                request.getDescription() != null ? request.getDescription()
                        : "Musteri tahsilati - " + request.getPaymentType().getDescription());

        payment.setAccountTransactionId(accountTransactionService.save(tx).getId());
        return save(payment);
    }

    /** Tedarikçiye ödeme: SupplierAccountService üzerinden bakiye güncelle */
    private Payment createSupplierPayment(PaymentRequest request, Payment.PaymentBuilder builder) {
        Supplier supplier = supplierService.findById(request.getSupplierId())
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + request.getSupplierId()));
        builder.supplier(supplier);
        Payment payment = save(builder.build());

        SupplierAccount savedAcct = supplierAccountService.applyCredit(supplier, request.getAmount());

        AccountTransaction tx = buildTransaction(
                supplier, null, payment,
                TransactionType.SUPPLIER_PAYMENT,
                BigDecimal.ZERO, request.getAmount(),
                savedAcct.getCurrentBalance(),
                request.getReferenceNumber(),
                request.getDescription() != null ? request.getDescription()
                        : "Tedarikci odemesi - " + request.getPaymentType().getDescription());

        payment.setAccountTransactionId(accountTransactionService.save(tx).getId());
        return save(payment);
    }

    // =========================================================================
    // OKUMA
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public PaymentResponse getPayment(String id) {
        return mapToResponse(findById(id)
                .orElseThrow(() -> new RuntimeException("Odeme bulunamadi: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentResponse> getByCustomer(String customerId) {
        return dao.findByCustomerId(customerId).stream().map(this::mapToResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentResponse> getBySupplier(String supplierId) {
        return dao.findBySupplierId(supplierId).stream().map(this::mapToResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentResponse> getBySale(String saleId) {
        return dao.findBySaleId(saleId).stream().map(this::mapToResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentResponse> getByPurchase(String purchaseId) {
        return dao.findByPurchaseId(purchaseId).stream().map(this::mapToResponse).toList();
    }

    // =========================================================================
    // İPTAL / ONAY
    // =========================================================================

    @Override
    public PaymentResponse cancelPayment(String id, String reason) {
        log.info("Odeme iptal ediliyor: id={}", id);

        Payment payment = findById(id)
                .orElseThrow(() -> new RuntimeException("Odeme bulunamadi: " + id));

        if (Boolean.TRUE.equals(payment.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Cari hesap ters kaydı — ilgili Account servisleri üzerinden
        if (payment.getCustomer() != null) {
            customerAccountService.reverseCredit(payment.getCustomer(), payment.getAmount());
        }
        if (payment.getSupplier() != null) {
            supplierAccountService.reverseCredit(payment.getSupplier(), payment.getAmount());
        }

        // AccountTransaction iptal — AccountTransactionService üzerinden
        if (payment.getAccountTransactionId() != null) {
            accountTransactionService.findById(payment.getAccountTransactionId())
                    .ifPresent(tx -> {
                        tx.setIsCancelled(true);
                        tx.setCancelledDate(LocalDateTime.now());
                        tx.setCancelledBy("Odeme iptali: " + id);
                        accountTransactionService.save(tx);
                    });
        }

        payment.cancel(reason);
        return mapToResponse(save(payment));
    }

    @Override
    public PaymentResponse verifyPayment(String id, String verifiedBy) {
        log.info("Odeme onaylaniyor: id={}", id);

        Payment payment = findById(id)
                .orElseThrow(() -> new RuntimeException("Odeme bulunamadi: " + id));

        if (Boolean.TRUE.equals(payment.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
        if (Boolean.TRUE.equals(payment.getIsVerified())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        payment.verify(verifiedBy != null ? verifiedBy : "Sistem");
        return mapToResponse(save(payment));
    }

    @Override
    public Payment savePayment(Payment payment) {
        return save(payment);
    }

    // =========================================================================
    // YARDIMCI
    // =========================================================================

    private AccountTransaction buildTransaction(
            Supplier supplier, Customer customer, Payment payment,
            TransactionType type, BigDecimal debit, BigDecimal credit,
            BigDecimal balance, String referenceNumber, String description) {

        return AccountTransaction.builder()
                .supplier(supplier)
                .customer(customer)
                .payment(payment)
                .transactionType(type)
                .debitAmount(debit)
                .creditAmount(credit)
                .balance(balance)
                .referenceId(payment.getId())
                .referenceType("PAYMENT")
                .referenceNumber(referenceNumber)
                .description(description)
                .transactionDate(LocalDateTime.now())
                .isOverdue(false)
                .isCancelled(false)
                .build();
    }

    private void validate(PaymentRequest request) {
        if (request.getCustomerId() == null && request.getSupplierId() == null) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
        if (request.getCustomerId() != null && request.getSupplierId() != null) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
    }
}
