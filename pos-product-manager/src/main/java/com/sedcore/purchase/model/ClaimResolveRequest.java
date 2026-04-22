package com.sedcore.purchase.model;

import com.sedcore.common.enums.ClaimStatus;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

/**
 * SupplierClaim kapatma isteği.
 *
 * <pre>
 * resolution = RESOLVED_DISCOUNT  → creditNoteNumber tavsiye edilir
 * resolution = RESOLVED_DELIVERY  → resolvedByPurchaseId doldurulmalı
 * resolution = RESOLVED_RETURN    → resolvedAmount = iade edilen nakit
 * resolution = CANCELLED          → hatalı açılmış claim iptali
 * </pre>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClaimResolveRequest {

    @NotNull(message = "Çözüm tipi zorunludur")
    private ClaimStatus resolution;

    /** Kapatılan tutar — null ise claim.claimAmount'un tamamı kabul edilir */
    private BigDecimal resolvedAmount;

    /** İskonto/kredi notu ile kapatmada tedarikçi belge numarası */
    private String creditNoteNumber;

    /** Teslimat ile kapatmada yeni satın alma ID'si */
    private String resolvedByPurchaseId;

    private String notes;
}
