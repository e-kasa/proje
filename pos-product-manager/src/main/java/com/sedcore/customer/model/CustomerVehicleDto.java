package com.sedcore.customer.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sprint 9 — CustomerVehicle create/update isteği.
 *
 * <p>plateDisplay zorunlu (kullanıcı girişi); backend normalize edip plate_normalized'e yazar.
 * vehicleId opsiyonel (Vehicle katalogundan seçildiyse). make/model/year freeform fallback.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerVehicleDto {

    @NotBlank(message = "Plaka zorunludur")
    @Size(max = 20, message = "Plaka en fazla 20 karakter olmalı")
    private String plateDisplay;

    /** Opsiyonel — Vehicle katalog FK (varsa make/model/year override edilir) */
    private String vehicleId;

    @Size(max = 50)
    private String make;

    @Size(max = 100)
    private String model;

    private Integer yearOfManufacture;

    private String notes;

    private Boolean isActive;
}
