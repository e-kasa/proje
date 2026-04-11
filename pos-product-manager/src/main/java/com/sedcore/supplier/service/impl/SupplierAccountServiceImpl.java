package com.sedcore.supplier.service.impl;

import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.supplier.model.SupplierAccountResponse;
import com.sedcore.supplier.repository.SupplierAccountRepository;
import com.sedcore.supplier.repository.SupplierRepository;
import com.sedcore.supplier.service.SupplierAccountService;
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
public class SupplierAccountServiceImpl
        extends BaseDbServiceImp<SupplierAccountRepository, SupplierAccount>
        implements SupplierAccountService {

    // SupplierRepository aynı domain (tedarikçi) içinde olduğundan doğrudan inject edilir.
    @Autowired
    private SupplierRepository supplierRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return SupplierAccountResponse.class;
    }

    // =========================================================================
    // MAPPER
    // =========================================================================

    private SupplierAccountResponse mapToResponse(SupplierAccount acct) {
        return SupplierAccountResponse.builder()
                .id(acct.getId())
                .supplierId(acct.getSupplier().getId())
                .supplierName(acct.getSupplier().getName())
                .creditLimit(acct.getSupplier().getCreditLimit())
                .currentBalance(acct.getCurrentBalance())
                .totalDebt(acct.getTotalDebt())
                .totalCredit(acct.getTotalCredit())
                .overdueAmount(acct.getOverdueAmount())
                .availableCreditLimit(acct.getAvailableCreditLimit())
                .isCreditLimitExceeded(acct.getIsCreditLimitExceeded())
                .totalTransactionCount(acct.getTotalTransactionCount())
                .lastTransactionDate(acct.getLastTransactionDate())
                .lastPaymentDate(acct.getLastPaymentDate())
                .lastPurchaseDate(acct.getLastPurchaseDate())
                .build();
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
}
