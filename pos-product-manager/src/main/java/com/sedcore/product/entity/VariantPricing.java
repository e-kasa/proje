package com.sedcore.product.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "variant_pricing")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VariantPricing extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(nullable = false)
    private BigDecimal purchasePrice;

    @Column(nullable = false)
    private BigDecimal salePrice;

    private String currency = "TRY";

    private LocalDateTime validFrom = LocalDateTime.now();

    /** KDV oranı (%) — Örn: 0, 1, 8, 10, 18, 20 */
    @Column(name = "vat_rate", precision = 5, scale = 2)
    private BigDecimal vatRate;

    /** ÖTV oranı (%) — Opsiyonel, ÖTV'ye tabi ürünler için */
    @Column(name = "special_tax_rate", precision = 5, scale = 2)
    private BigDecimal specialTaxRate;

    /** Satış fiyatı KDV dahil mi? true=KDV dahil, false=KDV hariç */
    @Column(name = "vat_included", nullable = false, columnDefinition = "boolean DEFAULT false")
    private Boolean vatIncluded = false;

    /** Stopaj oranı (%) — Opsiyonel */
    @Column(name = "withholding_tax_rate", precision = 5, scale = 2)
    private BigDecimal withholdingTaxRate;

    /** Vergiden muaf mı? */
    @Column(name = "tax_exempt", nullable = false, columnDefinition = "boolean DEFAULT false")
    private Boolean taxExempt = false;

}
