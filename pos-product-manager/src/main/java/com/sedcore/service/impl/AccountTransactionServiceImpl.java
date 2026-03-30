package com.sedcore.service.impl;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.AccountTransactionResponse;
import com.sedcore.repository.AccountTransactionRepository;
import com.sedcore.service.AccountTransactionService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.PropertyValues;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Slf4j
@Transactional
public class AccountTransactionServiceImpl
        extends BaseDbServiceImp<AccountTransactionRepository, AccountTransaction>
        implements AccountTransactionService {

    @Override
    public Class<?> getDTOClassForService() {
        return AccountTransactionResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private AccountTransactionResponse mapToResponse(AccountTransaction tx) {
        AccountTransactionResponse.AccountTransactionResponseBuilder builder =
                AccountTransactionResponse.builder()
                        .id(tx.getId())
                        .transactionType(tx.getTransactionType())
                        .transactionTypeLabel(
                                tx.getTransactionType() != null
                                        ? tx.getTransactionType().getDescription()
                                        : null)
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

        // Tedarikçi bilgisi
        if (tx.getSupplier() != null) {
            builder.supplierId(tx.getSupplier().getId())
                   .supplierName(tx.getSupplier().getName());
        }

        // Müşteri bilgisi
        if (tx.getCustomer() != null) {
            builder.customerId(tx.getCustomer().getId())
                   .customerName(tx.getCustomer().getName());
        }

        return builder.build();
    }

    // =========================================================================
    // OKUMA İŞLEMLERİ
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public AccountTransactionResponse getTransaction(String id) {
        log.info("Cari hareket getiriliyor: id={}", id);
        AccountTransaction tx = findById(id)
                .orElseThrow(() -> new RuntimeException("Cari hareket bulunamadi: " + id));
        return mapToResponse(tx);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getBySupplier(String supplierId) {
        log.info("Tedarikci hareketleri getiriliyor: supplierId={}", supplierId);
        return dao.findBySupplierId(supplierId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getBySupplierAndType(String supplierId, TransactionType type) {
        log.info("Tedarikci hareketleri (tip filtreli) getiriliyor: supplierId={}, type={}", supplierId, type);
        return dao.findBySupplierIdAndTransactionType(supplierId, type)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getByCustomer(String customerId) {
        log.info("Musteri hareketleri getiriliyor: customerId={}", customerId);
        return dao.findByCustomerId(customerId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getByPurchase(String purchaseId) {
        log.info("Satin alma hareketleri getiriliyor: purchaseId={}", purchaseId);
        return dao.findByPurchaseId(purchaseId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // =========================================================================
    // İPTAL İŞLEMİ
    // =========================================================================

    @Override
    public AccountTransactionResponse cancelTransaction(String id, String reason) {
        log.info("Cari hareket iptal ediliyor: id={}, reason={}", id, reason);

        AccountTransaction tx = findById(id)
                .orElseThrow(() -> new RuntimeException("Cari hareket bulunamadi: " + id));

        if (Boolean.TRUE.equals(tx.getIsCancelled())) {
            throw new RuntimeException("Bu hareket zaten iptal edilmis: " + id);
        }

        tx.setIsCancelled(true);
        tx.setCancelledDate(LocalDateTime.now());
        tx.setCancelledBy(reason != null ? reason : "Manuel iptal");

        AccountTransaction saved = save(tx);
        log.info("Cari hareket iptal edildi: id={}", saved.getId());

        return mapToResponse(saved);
    }

    @Override
    public List<AccountTransactionResponse> findBySupplierId(String supplierId) {
        return toDTOList(dao.findBySupplierId(supplierId),AccountTransactionResponse.class);
    }
}
