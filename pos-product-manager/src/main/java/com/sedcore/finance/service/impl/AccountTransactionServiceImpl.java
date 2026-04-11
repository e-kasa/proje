package com.sedcore.finance.service.impl;

import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.sedcore.finance.service.AccountTransactionService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
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

    @Override
    public AccountTransactionResponse toResponse(AccountTransaction tx) {
        AccountTransactionResponse dto = toDTO(tx);

        // transactionTypeLabel — enum'dan hesaplanan alan, BeanUtils kopyalamaz
        dto.setTransactionTypeLabel(
                tx.getTransactionType() != null ? tx.getTransactionType().getDescription() : null);

        // Tedarikçi FK alanları
        if (tx.getSupplier() != null) {
            dto.setSupplierId(tx.getSupplier().getId());
            dto.setSupplierName(tx.getSupplier().getName());
        }

        // Müşteri FK alanları
        if (tx.getCustomer() != null) {
            dto.setCustomerId(tx.getCustomer().getId());
            dto.setCustomerName(tx.getCustomer().getName());
        }

        return dto;
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
        return toResponse(tx);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getBySupplier(String supplierId) {
        log.info("Tedarikci hareketleri getiriliyor: supplierId={}", supplierId);
        return dao.findBySupplierId(supplierId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getBySupplierAndType(String supplierId, TransactionType type) {
        log.info("Tedarikci hareketleri (tip filtreli) getiriliyor: supplierId={}, type={}", supplierId, type);
        return dao.findBySupplierIdAndTransactionType(supplierId, type)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getByCustomer(String customerId) {
        log.info("Musteri hareketleri getiriliyor: customerId={}", customerId);
        return dao.findByCustomerId(customerId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AccountTransactionResponse> getByPurchase(String purchaseId) {
        log.info("Satin alma hareketleri getiriliyor: purchaseId={}", purchaseId);
        return dao.findByPurchaseId(purchaseId)
                .stream()
                .map(this::toResponse)
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
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        tx.setIsCancelled(true);
        tx.setCancelledDate(LocalDateTime.now());
        tx.setCancelledBy(reason != null ? reason : "Manuel iptal");

        AccountTransaction saved = save(tx);
        log.info("Cari hareket iptal edildi: id={}", saved.getId());

        return toResponse(saved);
    }

    @Override
    public List<AccountTransactionResponse> findBySupplierId(String supplierId) {
        return toDTOList(dao.findBySupplierId(supplierId),AccountTransactionResponse.class);
    }
}
