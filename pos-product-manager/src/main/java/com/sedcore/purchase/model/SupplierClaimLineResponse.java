package com.sedcore.purchase.model;

import com.sedcore.common.enums.ClaimReason;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierClaimLineResponse {

    private String id;
    private String variantId;
    private String variantSku;
    private String productName;

    private Integer expectedQty;
    private Integer receivedQty;
    private Integer shortageQty;

    private BigDecimal unitPrice;
    private BigDecimal lineAmount;

    private ClaimReason reason;
    private String notes;

    private Integer resolvedQty;
    private BigDecimal resolvedAmount;
    private Boolean isResolved;
}
