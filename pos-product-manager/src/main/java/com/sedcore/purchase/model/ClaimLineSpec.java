package com.sedcore.purchase.model;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.product.entity.ProductVariant;

import java.math.BigDecimal;

/**
 * SupplierClaim satırı oluşturmak için servis içi spec.
 *
 * <p>Batch giriş akışında her eksik variant için bir spec üretilir ve
 * {@code SupplierClaimService.openClaim(purchase, specs, notes)}'a iletilir.</p>
 */
public record ClaimLineSpec(
        ProductVariant variant,
        String variantSku,
        String productName,
        int expectedQty,
        int receivedQty,
        BigDecimal unitPrice,
        ClaimReason reason,
        String lineNote
) {
    public int shortageQty() {
        return Math.max(0, expectedQty - receivedQty);
    }

    public BigDecimal lineAmount() {
        return unitPrice.multiply(BigDecimal.valueOf(shortageQty()));
    }
}
