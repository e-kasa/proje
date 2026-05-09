package com.sedcore.finance.service.impl;

import com.sedcore.finance.entity.Payment;
import com.sedcore.finance.entity.PaymentAllocation;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.sales.entity.Sale;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.finance.model.AllocationRequest;
import com.sedcore.finance.model.PaymentRequest;
import com.sedcore.finance.model.PaymentResponse;
import com.sedcore.finance.repository.PaymentAllocationRepository;
import com.sedcore.finance.repository.PaymentRepository;
import com.sedcore.finance.service.PaymentService;
import com.sedcore.finance.service.AccountTransactionService;
import com.sedcore.sales.service.SaleService;
import com.sedcore.purchase.service.PurchaseService;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.supplier.service.SupplierService;
import com.sedcore.supplier.service.SupplierAccountService;
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

    @Autowired
    private PaymentAllocationRepository paymentAllocationRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return PaymentResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private PaymentResponse mapToResponse(Payment p) {
        PaymentResponse dto = toDTO(p);

        // paymentTypeLabel — enum'dan hesaplanan alan
        dto.setPaymentTypeLabel(p.getPaymentType() != null ? p.getPaymentType().getDescription() : null);

        // FK ilişkilerinden gelen alanlar — BeanUtils doğrudan kopyalamaz
        if (p.getCustomer() != null) {
            dto.setCustomerId(p.getCustomer().getId());
            dto.setCustomerName(p.getCustomer().getName());
        }
        if (p.getSupplier() != null) {
            dto.setSupplierId(p.getSupplier().getId());
            dto.setSupplierName(p.getSupplier().getName());
        }
        if (p.getSale() != null) dto.setSaleId(p.getSale().getId());
        if (p.getPurchase() != null) dto.setPurchaseId(p.getPurchase().getId());

        return dto;
    }

    // =========================================================================
    // ÖDEME OLUŞTURMA
    // =========================================================================

    @Override
    @SuppressWarnings("deprecation")  // PaymentRequest.saleId tek-FK geriye uyum (Sprint 9'da kaldırılacak)
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
        Payment saved = save(payment);

        // Sprint 7: Sale-Payment many-to-many allocation kayıtları (sale-bazlı raporlama için)
        createAllocations(saved, request);
        return saved;
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
        Payment saved = save(payment);

        // Tedarikçi tarafında allocation şu an tek-FK (Payment.purchase) yeterli;
        // ileride PurchaseAllocation için aynı pattern eklenebilir. Şimdilik no-op.
        return saved;
    }

    // =========================================================================
    // PAYMENT ALLOCATION (Sprint 7 — Sale-Payment many-to-many)
    // =========================================================================

    /**
     * Payment'i bir veya daha fazla satışa dağıtır.
     *
     * Davranış:
     *   - request.allocations boş + request.saleId boş → 1 "genel ödeme" allocation (sale=null)
     *   - request.allocations boş + request.saleId dolu → 1 allocation (sale=saleId, amount=payment.amount)
     *     (geriye uyum, deprecated)
     *   - request.allocations dolu → SUM kontrolü, her bir allocation insert
     *
     * Hata: SUM(allocations.amount) != payment.amount → exception
     */
    @SuppressWarnings("deprecation")  // PaymentRequest.saleId tek-FK geriye uyum (Sprint 9'da kaldırılacak)
    private void createAllocations(Payment payment, PaymentRequest request) {
        List<AllocationRequest> reqAllocations = request.getAllocations();

        // Etkin allocation listesini hesapla
        List<AllocationRequest> effective;
        if (reqAllocations != null && !reqAllocations.isEmpty()) {
            // Çoklu allocation: SUM kontrolü
            BigDecimal sum = reqAllocations.stream()
                    .map(AllocationRequest::getAmount)
                    .filter(a -> a != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            if (sum.compareTo(payment.getAmount()) != 0) {
                throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
            }
            effective = reqAllocations;
        } else {
            // Tek allocation oluştur (saleId varsa o satışa, yoksa genel)
            effective = List.of(new AllocationRequest(request.getSaleId(), payment.getAmount()));
        }

        for (AllocationRequest a : effective) {
            Sale sale = (a.getSaleId() != null && !a.getSaleId().isBlank())
                    ? saleService.getEntity(a.getSaleId())
                    : null;

            PaymentAllocation pa = PaymentAllocation.builder()
                    .payment(payment)
                    .sale(sale)
                    .amount(a.getAmount())
                    .allocatedAt(LocalDateTime.now())
                    .build();

            // Multi-tenant: TOpenSimpleCompanyEntity zorunlu companyCode + audit alanları
            pa.setCompanyCode(payment.getCompanyCode());
            pa.setCreateUser(payment.getCreateUser() != null ? payment.getCreateUser() : "SYSTEM");
            pa.setCreateTime(java.util.Calendar.getInstance().getTime());

            paymentAllocationRepository.save(pa);

            // Sprint 11g hot-fix — Sale.paidAmount denormalize alanını güncelle.
            // Bu olmadan Sale.remainingAmount değişmiyor, status "pending" kalıyor,
            // "ödenmemiş plakalı satışlar" listesi aynı satışı tekrar gösteriyor.
            // İptal/iade akışında sale.paidAmount geri yazımı ileri sprint kapsamı.
            if (sale != null && a.getAmount() != null) {
                BigDecimal current = sale.getPaidAmount() != null
                        ? sale.getPaidAmount() : BigDecimal.ZERO;
                sale.setPaidAmount(current.add(a.getAmount()));
                saleService.save(sale);
            }
        }

        log.info("PaymentAllocation oluşturuldu: paymentId={}, allocationCount={}",
                payment.getId(), effective.size());
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

    @Override
    @Transactional(readOnly = true)
    public List<PaymentResponse> getAll() {
        List<PaymentResponse> out = new java.util.ArrayList<>();
        dao.findAll().forEach(p -> out.add(mapToResponse(p)));
        return out;
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
