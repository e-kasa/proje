package com.sedcore.autoparts.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrossReferenceRequest {

    private String variantId;

    @NotBlank(message = "Capraz referans numarasi zorunludur")
    private String crossRefNumber;

    private String crossRefBrand;

    private String notes;
}
