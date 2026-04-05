package com.sedcore.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleCompatibilityResponse {

    private String id;
    private String variantId;
    private String variantSku;
    private String variantName;
    private String vehicleId;
    private String vehicleMake;
    private String vehicleModel;
    private Integer vehicleYearStart;
    private Integer vehicleYearEnd;
    private String vehicleEngineType;
    private String notes;
    private Boolean isVerified;
}
