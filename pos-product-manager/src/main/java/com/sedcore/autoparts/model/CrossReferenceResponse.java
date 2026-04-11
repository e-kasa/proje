package com.sedcore.autoparts.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrossReferenceResponse extends DtoBaseModel {

    private String id;
    private String variantId;
    private String crossRefNumber;
    private String crossRefBrand;
    private String notes;
}
