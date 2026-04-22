package com.sedcore.purchase.entity;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.supplier.entity.Supplier;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Tedarikçi Alacak Talebi — eksik veya hasarlı teslimat nedeniyle
 * tedarikçiden beklenen tutar/mal takibi.
 *
 * <p>Bir claim'in yaşam döngüsü:</p>
 * <pre>
 * createPurchase() ile shortage > 0 ise otomatik OPEN açılır
 *   └─ applyDiscount()   → RESOLVED_DISCOUNT
 *   └─ createPurchase()  → RESOLVED_DELIVERY  (yeni irsaliye ile kapatılır)
 *   └─ nakit iade        → RESOLVED_RETURN
 *   └─ hatalıysa         → CANCELLED
 * </pre>
 */
@Entity
@Table(name = "supplier_claims", indexes = {
        @Index(name = "idx_claim_supplier",       columnList = "supplier_id,status"),
        @Index(name = "idx_claim_purchase",       columnList = "purchase_id"),
        @Index(name = "idx_claim_company_status", columnList = "company_code,status")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class SupplierClaim extends TOpenSimpleCompanyEntity {

    // ── İlişkiler ────────────────────────────────────────────────────────────

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "supplier_id", nullable = false)
    private Supplier supplier;

    /** Eksik teslimatın kaynaklandığı satın alma belgesi */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "purchase_id", nullable = false)
    private Purchase sourcePurchase;

    // ── Talep bilgileri ───────────────────────────────────────────────────────

    @Column(name = "claim_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal claimAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "claim_reason", length = 20, nullable = false)
    private ClaimReason claimReason;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 30, nullable = false)
    @Builder.Default
    private ClaimStatus status = ClaimStatus.OPEN;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ── Çözüm alanları — status OPEN dışına çıkınca dolar ────────────────────

    /**
     * Eksik mallar bir sonraki irsaliyeyle geldiyse,
     * o satın almaya referans verilir.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_purchase_id")
    private Purchase resolvedByPurchase;

    /** Tedarikçinin düzenlediği iskonto/kredi notu numarası */
    @Column(name = "credit_note_number", length = 100)
    private String creditNoteNumber;

    /** Gerçekte kapatılan tutar (kısmi çözümde claimAmount'tan farklı olabilir) */
    @Column(name = "resolved_amount", precision = 15, scale = 2)
    private BigDecimal resolvedAmount;

    @Column(name = "resolved_date")
    private LocalDate resolvedDate;

    @Column(name = "resolved_by", length = 100)
    private String resolvedBy;

    /** Tüm satırlar çözülmüş mü? Aggregate sorgularını hızlandırmak için denormalize. */
    @Column(name = "is_fully_resolved")
    @Builder.Default
    private Boolean isFullyResolved = false;

    // ── Satır kalemleri ──────────────────────────────────────────────────────

    @OneToMany(mappedBy = "claim", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<SupplierClaimLine> lines = new ArrayList<>();

    @Version
    private Long version;
}
