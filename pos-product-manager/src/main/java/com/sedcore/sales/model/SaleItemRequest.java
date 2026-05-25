package com.sedcore.sales.model;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleItemRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    @NotNull(message = "Miktar zorunludur")
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;

    @NotNull(message = "Birim fiyat zorunludur")
    @Positive(message = "Birim fiyat pozitif olmalıdır")
    private BigDecimal unitPrice;

    @DecimalMin(value = "0.00", message = "İskonto oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "İskonto oranı 100'den büyük olamaz")
    private BigDecimal discountRate;

    @DecimalMin(value = "0.00", message = "KDV oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "KDV oranı 100'den büyük olamaz")
    private BigDecimal taxRate;

    /**
     * ÖTV oranı (%) — Sprint 2026-05-25. Opsiyonel; null veya 0 = ÖTV yok.
     * AUTO_PARTS sektöründe ürün varyantından gelir; FOOTWEAR'da gönderilmez.
     */
    @DecimalMin(value = "0.00", message = "ÖTV oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "ÖTV oranı 100'den büyük olamaz")
    private BigDecimal otvRate;

    /**
     * true ise {@code unitPrice} KDV+ÖTV dahil etiket fiyatıdır;
     * backend hesabı tersine ayrıştırır. Null/false → KDV hariç.
     */
    private Boolean vatIncluded;

    private String notes;
}
