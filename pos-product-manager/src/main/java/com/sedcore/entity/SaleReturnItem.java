package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * SaleReturnItem Entity — İade edilen her satış kalemi.
 *
 * Her bir {@link SaleReturn} kaydının kalem detaylarını tutar.
 */
@Entity
@Table(name = "sale_return_items", indexes = {
    @Index(name = "idx_sri_return",  columnList = "sale_return_id"),
    @Index(name = "idx_sri_variant", columnList = "variant_id")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleReturnItem extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_return_id", nullable = false)
    private SaleReturn saleReturn;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", precision = 15, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "line_total", precision = 15, scale = 2)
    private BigDecimal lineTotal;

    @Column(name = "reason", length = 50)
    private String reason;  // Kalem özelinde neden (opsiyonel)
}
