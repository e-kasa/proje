package com.sedcore.supplier.service.impl;

import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.finance.entity.Payment;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.common.enums.PaymentType;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.supplier.model.SupplierAccountResponse;
import com.sedcore.supplier.model.SupplierDto;
import com.sedcore.supplier.model.SupplierPaymentDto;
import com.sedcore.supplier.model.SupplierResponse;
import com.sedcore.supplier.repository.SupplierRepository;
import com.sedcore.finance.service.AccountTransactionService;
import com.sedcore.finance.service.PaymentService;
import com.sedcore.supplier.service.SupplierAccountService;
import com.sedcore.supplier.service.SupplierService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Supplier Service
 *
 * Repository erişimi sadece kendi domain reposu üzerinden (BaseDbServiceImp).
 * Çapraz domain erişimi için:
 *   SupplierAccountService    — tedarikçi cari hesap işlemleri
 *   AccountTransactionService  — cari hareketler
 *   @Lazy PaymentService      — Payment entity persist (savePayment).
 *                               PaymentServiceImpl de @Lazy SupplierService inject ettiğinden
 *                               döngüsel bağımlılığı kırmak için @Lazy zorunlu.
 *                               NOT: createPayment() ÇAĞRILMAZ — bakiye güncellemesi
 *                               bu sınıf içinde doğrudan orkestre edilir.
 */
@Service
@Slf4j
@Transactional
public class SupplierServiceImpl
        extends BaseDbServiceImp<SupplierRepository, Supplier>
        implements SupplierService {

    @Autowired
    private SupplierAccountService supplierAccountService;

    @Autowired
    private AccountTransactionService accountTransactionService;

    @Autowired
    @Lazy
    private PaymentService paymentService;

    @Override
    public Class<?> getDTOClassForService() {
        return SupplierResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    public SupplierResponse mapToResponse(Supplier supplier) {
        SupplierResponse.SupplierResponseBuilder builder = SupplierResponse.builder()
                .id(supplier.getId())
                .name(supplier.getName())
                .contactName(supplier.getContactName())
                .phone(supplier.getPhone())
                .email(supplier.getEmail())
                .address(supplier.getAddress())
                .notes(supplier.getNotes())
                .customerType(supplier.getCustomerType())
                .taxNumber(supplier.getTaxNumber())
                .taxOffice(supplier.getTaxOffice())
                .creditLimit(supplier.getCreditLimit())
                .paymentTermDays(supplier.getPaymentTermDays())
                .riskStatus(supplier.getRiskStatus())
                .isActive(supplier.getIsActive())
                .isDeleted(supplier.getIsDeleted());

        if (supplier.getAccount() != null) {
            builder.balance(supplier.getAccount().getCurrentBalance())
                   .totalDebt(supplier.getAccount().getTotalDebt())
                   .totalPaid(supplier.getAccount().getTotalCredit());
        }

        return builder.build();
    }

    private AccountTransactionResponse mapToTransactionResponse(AccountTransaction tx) {
        AccountTransactionResponse.AccountTransactionResponseBuilder builder =
                AccountTransactionResponse.builder()
                        .id(tx.getId())
                        .transactionType(tx.getTransactionType())
                        .transactionTypeLabel(tx.getTransactionType() != null
                                ? tx.getTransactionType().getDescription() : null)
                        .debitAmount(tx.getDebitAmount())
                        .creditAmount(tx.getCreditAmount())
                        .balance(tx.getBalance())
                        .description(tx.getDescription())
                        .notes(tx.getNotes())
                        .referenceId(tx.getReferenceId())
                        .referenceNumber(tx.getReferenceNumber())
                        .referenceType(tx.getReferenceType())
                        .transactionDate(tx.getTransactionDate())
                        .dueDate(tx.getDueDate())
                        .isOverdue(tx.getIsOverdue())
                        .isCancelled(tx.getIsCancelled())
                        .cancelledDate(tx.getCancelledDate())
                        .cancelledBy(tx.getCancelledBy());
        if (tx.getSupplier() != null) {
            builder.supplierId(tx.getSupplier().getId())
                   .supplierName(tx.getSupplier().getName());
        }
        return builder.build();
    }

    // =========================================================================
    // CRUD
    // =========================================================================

    @Override
    public Supplier createSupplier(SupplierDto dto) {
        log.info("Tedarikci olusturuluyor: name={}", dto.getName());
        return save(Supplier.builder()
                .name(dto.getName())
                .contactName(dto.getContactName())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .address(dto.getAddress())
                .notes(dto.getNotes())
                .customerType(dto.getCustomerType())
                .taxNumber(dto.getTaxNumber())
                .taxOffice(dto.getTaxOffice())
                .creditLimit(dto.getCreditLimit())
                .paymentTermDays(dto.getPaymentTermDays())
                .riskStatus(dto.getRiskStatus())
                .isActive(dto.getIsActive() != null ? dto.getIsActive() : true)
                .isDeleted(dto.getIsDeleted() != null ? dto.getIsDeleted() : false)
                .build());
    }

    @Override
    @Transactional(readOnly = true)
    public SupplierResponse getSupplier(String id) {
        Supplier supplier = findById(id)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + id));
        return mapToResponse(supplier);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<SupplierResponse> listSuppliers(Pageable pageable, Boolean isActive) {
        if (isActive != null) {
            return dao.findByIsActiveAndIsDeleted(isActive, false, pageable).map(this::mapToResponse);
        }
        return dao.findByIsDeleted(false, pageable).map(this::mapToResponse);
    }

    @Override
    public SupplierResponse updateSupplier(String id, SupplierDto dto) {
        Supplier supplier = findById(id)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + id));

        if (dto.getName() != null) supplier.setName(dto.getName());
        if (dto.getContactName() != null) supplier.setContactName(dto.getContactName());
        if (dto.getPhone() != null) supplier.setPhone(dto.getPhone());
        if (dto.getEmail() != null) supplier.setEmail(dto.getEmail());
        if (dto.getAddress() != null) supplier.setAddress(dto.getAddress());
        if (dto.getNotes() != null) supplier.setNotes(dto.getNotes());
        if (dto.getCreditLimit() != null) supplier.setCreditLimit(dto.getCreditLimit());
        if (dto.getPaymentTermDays() != null) supplier.setPaymentTermDays(dto.getPaymentTermDays());
        if (dto.getRiskStatus() != null) supplier.setRiskStatus(dto.getRiskStatus());
        if (dto.getIsActive() != null) supplier.setIsActive(dto.getIsActive());

        return mapToResponse(save(supplier));
    }

    @Override
    public void deleteSupplier(String id) {
        Supplier supplier = findById(id)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + id));
        supplier.setIsDeleted(true);
        supplier.setIsActive(false);
        save(supplier);
    }

    @Override
    public SupplierResponse toggleStatus(String id) {
        Supplier supplier = findById(id)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + id));
        supplier.setIsActive(supplier.getIsActive() == null || !supplier.getIsActive());
        return mapToResponse(save(supplier));
    }

    // =========================================================================
    // CARİ HESAP İŞLEMLERİ
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public SupplierAccountResponse getSupplierAccount(String supplierId) {
        log.info("Tedarikci cari hesap getiriliyor: id={}", supplierId);
        return supplierAccountService.getAccountResponse(supplierId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getSupplierTransactions(String supplierId) {
        log.info("Tedarikci hareketleri getiriliyor: id={}", supplierId);
        return accountTransactionService.getBySupplier(supplierId);
    }

    /**
     * Tedarikçiye ödeme kaydı.
     *
     * Doğrudan orkestrasyon — createPayment() delegasyonu kullanılmaz.
     * @Lazy PaymentService.createPayment() → @Lazy SupplierService.findById() zinciri
     * Hibernate session/transaction sınırını bozduğundan, SupplierAccount kayıtları
     * flush edilmeden kalıyordu.  Çözüm: her işlemi bu transaction içinde elle yapmak.
     *
     * Akış:
     *   1. Supplier ve SupplierAccount'u yükle / oluştur
     *   2. SupplierAccountService.applyCredit() → bakiyeyi güncelle ve kaydet
     *   3. Payment entity'yi paymentService.savePayment() ile kaydet (sadece persist, yan etki yok)
     *   4. AccountTransaction kaydet — savedPayment.id ile bağla
     *   5. Payment'a accountTransactionId ata ve tekrar kaydet
     */
    @Override
    public SupplierAccountResponse recordPayment(String supplierId, SupplierPaymentDto dto) {
        log.info("Tedarikci odemesi kaydediliyor: supplierId={}, amount={}", supplierId, dto.getAmount());

        Supplier supplier = findById(supplierId)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + supplierId));

        PaymentType paymentType = dto.getPaymentType() != null ? dto.getPaymentType() : PaymentType.CASH;
        String description = dto.getDescription() != null
                ? dto.getDescription()
                : "Tedarikci odemesi - " + paymentType.getDescription();

        // 1. SupplierAccount bakiyesini güncelle (aynı transaction içinde flush edilir)
        SupplierAccount savedAcct = supplierAccountService.applyCredit(supplier, dto.getAmount());

        // 2. Payment entity kaydet — paymentService.savePayment() sadece persist yapar
        Payment payment = Payment.builder()
                .supplier(supplier)
                .paymentType(paymentType)
                .amount(dto.getAmount())
                .paymentDate(LocalDateTime.now())
                .referenceNumber(dto.getReferenceNumber())
                .description(description)
                .isCancelled(false)
                .isVerified(false)
                .build();
        Payment savedPayment = paymentService.savePayment(payment);

        // 3. AccountTransaction kaydet
        AccountTransaction tx = AccountTransaction.builder()
                .supplier(supplier)
                .payment(savedPayment)
                .transactionType(TransactionType.SUPPLIER_PAYMENT)
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

        log.info("Tedarikci odemesi tamamlandi: supplierId={}, paymentId={}, yeniBakiye={}",
                supplierId, savedPayment.getId(), savedAcct.getCurrentBalance());

        return supplierAccountService.getAccountResponse(supplierId);
    }

    @Override
    public SupplierAccountResponse updateCreditLimit(String supplierId, BigDecimal newLimit) {
        log.info("Kredi limiti guncelleniyor: supplierId={}, newLimit={}", supplierId, newLimit);

        Supplier supplier = findById(supplierId)
                .orElseThrow(() -> new RuntimeException("Tedarikci bulunamadi: " + supplierId));
        supplier.setCreditLimit(newLimit);
        save(supplier);

        // SupplierAccountService üzerinden hesaplanan alanları yenile
        return supplierAccountService.recalculate(supplierId);
    }
}
