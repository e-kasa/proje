package com.sedcore.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BrandRequest {

    @NotBlank(message = "Marka adı zorunludur")
    private String name;

    private String code;

    private String description;

    private Boolean isActive = true;
}
