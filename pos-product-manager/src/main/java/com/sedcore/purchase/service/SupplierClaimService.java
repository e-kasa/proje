package com.sedcore.purchase.service;

import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.purchase.entity.SupplierClaim;
import com.sedcore.purchase.model.ClaimLineSpec;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.towpen.base.security.BaseDbService;

import java.math.BigDecimal;
import java.util.List;

public interface SupplierClaimService extends BaseDbService<SupplierClaim> {

    /**
     * Satır detaylı claim açar — batch giriş akışında variant bazında eksik/hasar kaydı.
     * Aggregate tutar ve ana sebep specs'ten türetilir.
     */
    SupplierClaim openClaim(Purchase purchase, List<ClaimLineSpec> lines, String notes);

    /**
     * Claim kapatır.
     * <ul>
     *   <li>RESOLVED_DISCOUNT  → sadece claim kapanır (finansal etki yok — zaten debit yazılmamıştı)</li>
     *   <li>RESOLVED_DELIVERY  → resolvedByPurchase referansı set edilir</li>
     *   <li>RESOLVED_RETURN    → nakit iade olarak işaretlenir</li>
     *   <li>CANCELLED          → hatalı claim iptali</li>
     * </ul>
     */
    SupplierClaimResponse resolveClaim(String claimId, ClaimResolveRequest request);

    /** Bir purchase'a ait tüm claim'leri döner. */
    List<SupplierClaimResponse> listByPurchase(String purchaseId);

    /** Tedarikçiye ait claim'leri (opsiyonel durum filtresiyle) döner. */
    List<SupplierClaimResponse> listBySupplier(String supplierId, ClaimStatus status);

    /** Tedarikçinin açık claim toplamı — applyDiscount validasyonunda kullanılır. */
    BigDecimal openClaimTotal(String supplierId);

    /** Claim'i iptal eder (hatalı açılmış → CANCELLED). Satırların resolve durumu değişmez. */
    SupplierClaimResponse cancelClaim(String claimId, String reason);

    /** Tek claim'i detayıyla (satırlar dolu) döner. */
    SupplierClaimResponse getDetail(String claimId);

    /** Listeleme — status/supplierId kombine filtre. */
    List<SupplierClaimResponse> listClaims(String supplierId, ClaimStatus status);

    SupplierClaimResponse toResponse(SupplierClaim claim);

    SupplierClaimResponse toResponseWithLines(SupplierClaim claim);
}
