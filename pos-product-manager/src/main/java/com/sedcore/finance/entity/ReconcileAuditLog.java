package com.sedcore.finance.entity;

import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.common.enums.ReconcileScope;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Cari hesap drift reconcile denetim kaydı.
 *
 * Ledger (AccountTransaction) ↔ denormalize (CustomerAccount / SupplierAccount) karşılaştırmasında
 * tespit edilen ve düzeltilen her sapma için satır yazılır. SINGLE = tek hesap tetiği,
 * ALL = reconcileAll sweep özeti (korrekte sayılmış hesap başına ayrı kayıt + sweep özet kaydı).
 *
 * Tetikleyen kullanıcı ve zaman bilgisi base class (createUser / createTime) tarafından dolar.
 */
@Entity
@Table(name = "reconcile_audit_logs", indexes = {
        @Index(name = "idx_reconcile_audit_entity", columnList = "entity_type, account_id"),
        @Index(name = "idx_reconcile_audit_scope", columnList = "scope"),
        @Index(name = "idx_reconcile_audit_company", columnList = "company_code, create_time")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReconcileAuditLog extends TOpenSimpleCompanyEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "scope", nullable = false, length = 10)
    private ReconcileScope scope;

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false, length = 10)
    private ReconcileEntityType entityType;

    @Column(name = "account_id", length = 36)
    private String accountId;

    @Column(name = "balance_before", precision = 15, scale = 2)
    private BigDecimal balanceBefore;

    @Column(name = "balance_after", precision = 15, scale = 2)
    private BigDecimal balanceAfter;

    @Column(name = "drift_amount", precision = 15, scale = 2)
    private BigDecimal driftAmount;

    @Column(name = "debt_before", precision = 15, scale = 2)
    private BigDecimal debtBefore;

    @Column(name = "debt_after", precision = 15, scale = 2)
    private BigDecimal debtAfter;

    @Column(name = "credit_before", precision = 15, scale = 2)
    private BigDecimal creditBefore;

    @Column(name = "credit_after", precision = 15, scale = 2)
    private BigDecimal creditAfter;

    @Column(name = "correction_count")
    @Builder.Default
    private Integer correctionCount = 1;
}
