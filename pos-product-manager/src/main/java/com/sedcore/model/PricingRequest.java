package com.sedcore.model;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PricingRequest {

    private BigDecimal purchasePrice;

    private BigDecimal salePrice;

    /** KDV oranı (%) — 0, 1, 8, 10, 18, 20 */
    private BigDecimal vatRate;

    /** Satış fiyatı KDV dahil mi? default false */
    private Boolean vatIncluded = false;

    /** ÖTV oranı (%) — Opsiyonel */
    private BigDecimal specialTaxRate;

    /** Stopaj oranı (%) — Opsiyonel */
    private BigDecimal withholdingTaxRate;

    /** Vergiden muaf mı? */
    private Boolean taxExempt = false;

}
