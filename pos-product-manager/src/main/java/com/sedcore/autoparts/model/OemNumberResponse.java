package com.sedcore.autoparts.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OemNumberResponse {

    private String id;
    private String variantId;
    private String oemNumber;
    private String manufacturer;
    private Boolean isPrimary;
}
