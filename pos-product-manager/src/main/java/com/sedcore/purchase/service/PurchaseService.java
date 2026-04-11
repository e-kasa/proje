package com.sedcore.purchase.service;

import com.sedcore.purchase.entity.Purchase;
import com.sedcore.purchase.model.PurchaseRequest;
import com.sedcore.purchase.model.PurchaseResponse;
import com.sedcore.purchase.model.PurchaseReturnRequest;
import com.sedcore.purchase.model.PurchaseReturnResponse;
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

    /**
     * Kısmi iade: seçilen kalemler için PURCHASE_RETURN_OUT stok hareketi,
     * SupplierAccount alacak kaydı ve AccountTransaction(SUPPLIER_RETURN).
     */
    PurchaseReturnResponse createPurchaseReturn(String purchaseId, PurchaseReturnRequest request);
}
