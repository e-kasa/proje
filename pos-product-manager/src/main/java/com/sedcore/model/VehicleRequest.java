package com.sedcore.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleRequest {

    @NotBlank(message = "Marka zorunludur")
    private String make;

    @NotBlank(message = "Model zorunludur")
    private String model;

    private Integer yearStart;

    private Integer yearEnd;

    private String engineType;

    private String fuelType;

    private String bodyType;

    private String platformCode;

    private Boolean isActive = true;
}
