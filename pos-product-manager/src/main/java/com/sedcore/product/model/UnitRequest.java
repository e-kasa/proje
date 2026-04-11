package com.sedcore.product.model;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitRequest {

    @NotBlank(message = "Birim kodu zorunludur")
    private String code;

    @NotBlank(message = "Birim adı zorunludur")
    private String name;

    private String symbol;

    private String type; // Sayılabilir | Tartılabilir | Ölçülebilir

    private Boolean isActive = true;
}
