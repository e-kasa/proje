package com.sedcore.finance.entity;

import com.sedcore.sales.entity.Sale;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * PaymentAllocation — Bir Payment'in bir veya daha fazla satışa dağıtımını kaydeder.
 *
 * Sprint 7'de eklendi (Sale-Payment many-to-many). Tek satışlı durumda da
 * 1 allocation kaydı tutulur — bu, ileride toplu ödeme (B3) eklenince sıfır
 * şema değişikliği sağlar.
 *
 * Kurallar:
 *   - SUM(amount) by paymentId == Payment.amount
 *   - sale null = "genel ödeme" (cari bakiyeye, belirli satışa değil)
 *   - allocatedAt audit için: kim ne zaman dağıttı izlenebilir
 *
 * @Version optimistic lock — concurrent allocation update korunur.
 *   ⚠️ data.sql seed yazılırsa version=0 zorunlu (project_ddl_strategy.md tuzak #3).
 */
@Entity
@Table(name = "payment_allocations", indexes = {
        @Index(name = "idx_pa_payment", columnList = "payment_id"),
        @Index(name = "idx_pa_sale", columnList = "sale_id"),
        @Index(name = "idx_pa_company", columnList = "company_code")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentAllocation extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "payment_id", nullable = false)
    private Payment payment;

    /** null = "genel ödeme" (cari bakiyeye, spesifik satışa değil) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id")
    private Sale sale;

    @Column(name = "amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(name = "allocated_at", nullable = false)
    private LocalDateTime allocatedAt;

    @Version
    private Long version;
}
