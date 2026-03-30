package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Varyant Fiyatlandırma Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PricingResponse {

    private String id;

    private String variantId;
    private String variantSku;

    private BigDecimal purchasePrice;
    private BigDecimal salePrice;

    /** KDV oranı (%) */
    private BigDecimal vatRate;

    /** Satış fiyatı KDV dahil mi? */
    private Boolean vatIncluded;

    /** ÖTV oranı (%) */
    private BigDecimal specialTaxRate;

    /** Stopaj oranı (%) */
    private BigDecimal withholdingTaxRate;

    /** Vergiden muaf mı? */
    private Boolean taxExempt;

    /** KDV dahil/hariç hesaplanmış satış fiyatı */
    private BigDecimal salePriceWithVat;

    private String currency;
    private LocalDateTime validFrom;
}
