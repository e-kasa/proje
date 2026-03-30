package com.sedcore.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BrandResponse {

    private String id;
    private String companyCode;
    private String name;
    private String code;
    private String description;
    private Boolean isActive;
}
