package com.sedcore.autoparts.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleCompatibilityRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    private String vehicleId;

    private List<String> vehicleIds;

    private String notes;

    private Boolean isVerified = false;
}
