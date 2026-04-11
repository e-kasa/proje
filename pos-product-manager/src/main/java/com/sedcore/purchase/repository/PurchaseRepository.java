package com.sedcore.purchase.repository;

import org.springframework.stereotype.Repository;

import com.sedcore.purchase.entity.Purchase;
import com.towpen.base.db.repository.BaseDaoRepository;

import java.util.List;
import java.util.Optional;
@Repository
public interface PurchaseRepository extends BaseDaoRepository<Purchase> {

    // Tedarikçiye göre satın almalar (supplier.id navigasyonu)
    List<Purchase> findBySupplierId(String supplierId);

    // Fatura numarasına göre
    Optional<Purchase> findByInvoiceNumber(String invoiceNumber);

    // İptal edilmemiş satın almalar
    List<Purchase> findByIsCancelledFalse();

    // Tedarikçi + iptal filtresi kombine
    List<Purchase> findBySupplierIdAndIsCancelledFalse(String supplierId);

    // İptal durumuna göre (parametre ile)
    List<Purchase> findByIsCancelled(Boolean isCancelled);

    // Tedarikçi + iptal durumu kombine (parametre ile)
    List<Purchase> findBySupplierIdAndIsCancelled(String supplierId, Boolean isCancelled);
}
