package com.sedcore.finance.entity;

import com.sedcore.common.enums.AccountAuditAction;
import com.sedcore.common.enums.AccountAuditEntityType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Sprint 30 — Müşteri / tedarikçi alan değişikliği denetim kaydı (issue P2.6).
 *
 * <p>Hibernate Envers yerine hafif custom tablo: tüm field-bazlı _AUD tabloları
 * yerine tek tablo + entity tipi diskriminatörü. Trade-off: transparent rollback
 * yok, entity-level snapshot yok; gainz: tek migration, sade okuma, sektörel
 * "X kullanıcısı creditLimit'i 5000→10000 yaptı" sorgusu kolay.
 *
 * <p>Bir update operasyonu N alan değiştiriyorsa N satır yazılır
 * (her satır {@code fieldName, oldValue, newValue} taşır). CREATE / DELETE /
 * RESTORE için tek satır (alan adı boş, değer alanları opsiyonel).
 *
 * <p>Tetikleyen kullanıcı ve zaman bilgisi base class (createUser / createTime)
 * tarafından dolar — security context'ten {@code BaseDbServiceImp.save()}
 * üzerinden gelir.
 *
 * <p>Multi-tenant: {@code companyCode} {@link TOpenSimpleCompanyEntity}
 * inherited.
 */
@Entity
@Table(name = "account_audit_logs", indexes = {
        @Index(name = "idx_account_audit_entity",
                columnList = "entity_type, entity_id, create_time"),
        @Index(name = "idx_account_audit_company",
                columnList = "company_code, create_time"),
        @Index(name = "idx_account_audit_field",
                columnList = "entity_type, field_name, create_time")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AccountAuditLog extends TOpenSimpleCompanyEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false, length = 10)
    private AccountAuditEntityType entityType;

    /** Customer veya Supplier id'si. */
    @Column(name = "entity_id", nullable = false, length = 36)
    private String entityId;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 16)
    private AccountAuditAction action;

    /**
     * UPDATE için zorunlu, diğer action'larda boş.
     * Örn: {@code "creditLimit"}, {@code "riskStatus"}, {@code "name"}.
     */
    @Column(name = "field_name", length = 64)
    private String fieldName;

    /** Eski değer (string serileştirme). */
    @Column(name = "old_value", length = 1024)
    private String oldValue;

    /** Yeni değer (string serileştirme). */
    @Column(name = "new_value", length = 1024)
    private String newValue;

    /** Operasyon nedeni — admin endpoint çağrısında opsiyonel açıklama. */
    @Column(name = "reason", length = 500)
    private String reason;
}
