package com.sedcore.service;

import com.sedcore.entity.Purchase;
import com.sedcore.model.PurchaseRequest;
import com.sedcore.model.PurchaseResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface PurchaseService extends BaseDbService<Purchase> {

    /** Tam akış: Purchase + StockMovements + SupplierAccount + AccountTransaction */
    PurchaseResponse createPurchase(PurchaseRequest request);

    /** İptal: PURCHASE_RETURN_OUT hareketleri + SupplierAccount ters kayıt + TX iptal */
    PurchaseResponse cancelPurchase(String id);

    /** Liste — supplierId ve isCancelled filtreli */
    List<PurchaseResponse> listPurchases(String supplierId, Boolean isCancelled);

    PurchaseResponse getPurchase(String id);

    /** Satın alma güncelleme: belge bilgileri + notlar */
    PurchaseResponse updatePurchase(String id, PurchaseRequest request);
}
