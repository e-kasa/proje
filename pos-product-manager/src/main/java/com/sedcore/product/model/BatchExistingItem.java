package com.sedcore.product.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

/**
 * Toplu ürün girişinde mevcut ürün kalemi.
 * Sadece stok + tedarikçi cari kaydı oluşturur — ürün verisi değişmez.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchExistingItem {

    /** Flutter tarafında BatchEntryRow.id değeri */
    private String tempId;

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    @NotNull
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;

    @NotNull
    @Positive(message = "Birim fiyat pozitif olmalıdır")
    private BigDecimal unitPrice;

    private BigDecimal taxRate;

    private String notes;
}
