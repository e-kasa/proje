package com.sedcore.autoparts.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OemNumberResponse extends DtoBaseModel {

    private String id;
    private String variantId;
    private String oemNumber;
    private String manufacturer;
    private Boolean isPrimary;
}
