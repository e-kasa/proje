package com.sedcore.sales.entity;

import java.math.BigDecimal;

import com.sedcore.product.entity.ProductVariant;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * SaleItem — Satışın satır kalemi.
 *
 * Her ürün satırı için indirim, KDV ve toplam kayıt altına alınır.
 * Vergi raporlaması ve iade hesaplaması bu tablodan yapılır.
 */
@Entity
@Table(name = "sale_items", indexes = {
    @Index(name = "idx_sale_item_sale", columnList = "sale_id"),
    @Index(name = "idx_sale_item_variant", columnList = "variant_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SaleItem extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id", nullable = false)
    private Sale sale;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", precision = 15, scale = 2, nullable = false)
    private BigDecimal unitPrice;

    @Column(name = "discount_rate", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal discountRate = BigDecimal.ZERO;

    @Column(name = "discount_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "tax_rate", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal taxRate = BigDecimal.ZERO;

    @Column(name = "tax_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal taxAmount = BigDecimal.ZERO;

    /** ÖTV oranı (%) — Sprint 2026-05-25. Sektör default'tan veya VariantPricing'ten gelir. */
    @Column(name = "otv_rate", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal otvRate = BigDecimal.ZERO;

    /** ÖTV tutarı — net × otvRate / 100. KDV matrahına dahildir. */
    @Column(name = "otv_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal otvAmount = BigDecimal.ZERO;

    @Column(name = "line_total", precision = 15, scale = 2, nullable = false)
    private BigDecimal lineTotal;

    @Column(name = "returned_quantity")
    @Builder.Default
    private Integer returnedQuantity = 0;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Version
    private Long version;
}
