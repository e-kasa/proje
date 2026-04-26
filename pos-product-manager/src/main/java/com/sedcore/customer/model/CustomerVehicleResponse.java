package com.sedcore.customer.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sprint 9 — CustomerVehicle yanıt DTO'su.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerVehicleResponse {

    private String id;
    private String customerId;
    private String plateDisplay;
    private String plateNormalized;
    private String vehicleId;
    private String make;
    private String model;
    private Integer yearOfManufacture;
    private String notes;
    private Boolean isActive;
    private String companyCode;
}
