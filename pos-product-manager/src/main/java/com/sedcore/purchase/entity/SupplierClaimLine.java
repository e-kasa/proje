package com.sedcore.purchase.entity;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.product.entity.ProductVariant;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Tedarikçi alacak talebi satırı — tek bir variant için eksik/hasarlı miktar kaydı.
 *
 * <p>Bir {@link SupplierClaim} birden fazla satır içerebilir. Satır, claim tutarının
 * hangi variant'tan ne kadar eksik geldiğini saklar. Denormalize alanlar (sku, name)
 * ürün sonradan silinse bile rapor için saklanabilmesi içindir.</p>
 */
@Entity
@Table(name = "supplier_claim_lines", indexes = {
        @Index(name = "idx_claim_line_claim",    columnList = "claim_id"),
        @Index(name = "idx_claim_line_variant",  columnList = "company_code,variant_id"),
        @Index(name = "idx_claim_line_resolved", columnList = "claim_id,is_resolved")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class SupplierClaimLine extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "claim_id", nullable = false)
    private SupplierClaim claim;

    /** Yeni ürün akışında ürün claim'den önce oluşturulur → her zaman dolu. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id")
    private ProductVariant variant;

    /** Denormalize: ürün silinse bile kayıt korunur. */
    @Column(name = "variant_sku", length = 100)
    private String variantSku;

    @Column(name = "product_name", length = 255)
    private String productName;

    @Column(name = "expected_qty", nullable = false)
    private Integer expectedQty;

    @Column(name = "received_qty", nullable = false)
    private Integer receivedQty;

    @Column(name = "unit_price", precision = 15, scale = 2, nullable = false)
    private BigDecimal unitPrice;

    /** shortageQty × unitPrice — hesaplanmış, audit için kaydedilmiş. */
    @Column(name = "line_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal lineAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "reason", length = 20, nullable = false)
    @Builder.Default
    private ClaimReason reason = ClaimReason.SHORTAGE;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ── Çözüm ───────────────────────────────────────────────────────────────

    @Column(name = "resolved_qty")
    @Builder.Default
    private Integer resolvedQty = 0;

    @Column(name = "resolved_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal resolvedAmount = BigDecimal.ZERO;

    @Column(name = "is_resolved")
    @Builder.Default
    private Boolean isResolved = false;

    @Version
    private Long version;

    // ── Helpers ─────────────────────────────────────────────────────────────

    public int shortageQty() {
        return Math.max(0, expectedQty - receivedQty);
    }

    public int remainingQty() {
        int rq = resolvedQty != null ? resolvedQty : 0;
        return Math.max(0, shortageQty() - rq);
    }
}
