package com.sedcore.product.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitResponse {

    private String id;
    private String companyCode;
    private String code;
    private String name;
    private String symbol;
    private String type;
    private Boolean isActive;
}
