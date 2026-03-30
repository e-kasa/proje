package com.sedcore.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.entity.Purchase;

import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductRequest {

    @NotBlank(message = "Ürün adı zorunludur")
    private String name;

    @NotBlank(message = "Stok kodu zorunludur")
    private String sku;
   
    private String slug;

    @NotNull(message = "Kategori ID zorunludur")
    private String categoryId;

    private String brand;

    private String unit; //birimi

    private String description;

}
