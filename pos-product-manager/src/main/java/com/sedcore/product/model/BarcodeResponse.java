package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Barkod Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BarcodeResponse {

    private String id;
    private String barcodeCode;
    private String barcodeType;
    private Boolean isPrimary;
    private Boolean isActive;
    private Long usageCount;
}