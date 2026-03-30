package com.sedcore.model;

import com.sedcore.enums.BarcodeType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Barkod Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BarcodeRequest {

    @NotBlank(message = "Barkod kodu zorunludur")
    private String code;

    @NotNull(message = "Barkod tipi zorunludur")
    private BarcodeType type; // BarcodeType enum string

    private Boolean isPrimary;
}