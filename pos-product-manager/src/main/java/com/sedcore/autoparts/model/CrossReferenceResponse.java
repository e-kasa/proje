package com.sedcore.autoparts.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrossReferenceResponse {

    private String id;
    private String variantId;
    private String crossRefNumber;
    private String crossRefBrand;
    private String notes;
}
