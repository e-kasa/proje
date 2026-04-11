package com.sedcore.catalog.model;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class CompanyCategoryBulkRequest {

    /**
     * Firmanın seçtiği tüm category_id listesi.
     * Mevcut seçimler bu listeyle tamamen değiştirilir.
     * Boş liste gönderilirse tüm kategori atamaları kaldırılır.
     */
    @NotNull(message = "Kategori listesi boş olamaz")
    private List<String> categoryIds;
}
