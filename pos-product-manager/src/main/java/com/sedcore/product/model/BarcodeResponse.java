package com.sedcore.product.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

/**
 * Barkod Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BarcodeResponse extends DtoBaseModel {

    private String id;
    private String barcodeCode;
    private String barcodeType;
    private Boolean isPrimary;
    private Boolean isActive;
    private Long usageCount;
}