package com.sedcore.product.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitResponse extends DtoBaseModel {

    private String id;
    private String companyCode;
    private String code;
    private String name;
    private String symbol;
    private String type;
    private Boolean isActive;
}
