package com.sedcore.purchase.model;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.purchase.entity.SupplierClaim;
import lombok.*;

import java.math.BigDecimal;

/**
 * BatchCreateResponse'a iliştirilen hafif claim özeti.
 * Batch giriş sonrası Flutter'ın "Talep #ID · tutar" toast'unu gösterebilmesi için.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierClaimSummary {

    private String claimId;
    private BigDecimal claimAmount;
    private int lineCount;
    private ClaimStatus status;
    private ClaimReason reason;

    public static SupplierClaimSummary of(SupplierClaim c) {
        return SupplierClaimSummary.builder()
                .claimId(c.getId())
                .claimAmount(c.getClaimAmount())
                .lineCount(c.getLines() != null ? c.getLines().size() : 0)
                .status(c.getStatus())
                .reason(c.getClaimReason())
                .build();
    }
}
