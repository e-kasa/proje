package com.sedcore.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OemNumberRequest {

    private String variantId;

    @NotBlank(message = "OEM numarasi zorunludur")
    private String oemNumber;

    private String manufacturer;

    private Boolean isPrimary = false;
}
