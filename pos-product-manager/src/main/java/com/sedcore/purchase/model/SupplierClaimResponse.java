package com.sedcore.purchase.model;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.common.enums.ClaimStatus;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierClaimResponse {

    private String id;

    private String supplierId;
    private String supplierName;

    private String sourcePurchaseId;
    private String invoiceNumber;

    private BigDecimal claimAmount;
    private ClaimReason claimReason;
    private ClaimStatus status;
    private String notes;

    // Çözüm alanları
    private String resolvedByPurchaseId;
    private String creditNoteNumber;
    private BigDecimal resolvedAmount;
    private LocalDate resolvedDate;
    private String resolvedBy;

    private Boolean isFullyResolved;

    private String createTime;

    /** Satır detayları — yalnızca detail endpoint'te dolu, list endpoint'inde boş/null olabilir. */
    private List<SupplierClaimLineResponse> lines;
}
