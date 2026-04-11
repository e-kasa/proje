package com.sedcore.autoparts.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleResponse {

    private String id;
    private String companyCode;
    private String make;
    private String model;
    private Integer yearStart;
    private Integer yearEnd;
    private String engineType;
    private String fuelType;
    private String bodyType;
    private String platformCode;
    private Boolean isActive;
}
