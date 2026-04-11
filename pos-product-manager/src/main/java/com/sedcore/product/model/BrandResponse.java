package com.sedcore.product.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BrandResponse extends DtoBaseModel {

    private String id;
    private String companyCode;
    private String name;
    private String code;
    private String description;
    private Boolean isActive;
}
