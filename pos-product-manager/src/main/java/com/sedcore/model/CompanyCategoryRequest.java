package com.sedcore.model;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class CompanyCategoryRequest {

    /** Tek kategori eklemek için */
    @NotBlank(message = "Kategori ID zorunludur")
    private String categoryId;

    private Integer displayOrder = 0;
}
