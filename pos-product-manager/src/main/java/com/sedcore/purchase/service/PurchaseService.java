package com.sedcore.purchase.service;

import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.PurchaseDiscountRequest;
import com.sedcore.purchase.model.PurchaseRequest;
import com.sedcore.purchase.model.PurchaseResponse;
import com.sedcore.purchase.model.PurchaseReturnRequest;
import com.sedcore.purchase.model.PurchaseReturnResponse;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface PurchaseService extends BaseDbService<Purchase> {

    /** Tam akış: Purchase + StockMovements + SupplierAccount + AccountTransaction.
     *  invoiceQty > receivedQty ise otomatik SupplierClaim açılır. */
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

    /**
     * Tedarikçi iskontosu / kredi notu uygular.
     * discountAmount ≤ purchase.shortageAmount olmalı.
     * Finansal etki: shortageAmount azalır, discountAmount birikir.
     * Cari hesaba credit yazılmaz (shortage için zaten debit yazılmamıştı).
     * AccountTransaction(DISCOUNT) audit amaçlı kaydedilir.
     */
    PurchaseResponse applyDiscount(String purchaseId, PurchaseDiscountRequest request);

    /** Purchase'a ait alacak taleplerini listeler */
    List<SupplierClaimResponse> listClaims(String purchaseId);

    /** Tedarikçiye ait alacak taleplerini listeler (opsiyonel durum filtresiyle) */
    List<SupplierClaimResponse> listClaimsBySupplier(String supplierId, ClaimStatus status);

    /** Claim'i kapatır (iskonto / teslimat / nakit iade / iptal) */
    SupplierClaimResponse resolveClaim(String claimId, ClaimResolveRequest request);
}
