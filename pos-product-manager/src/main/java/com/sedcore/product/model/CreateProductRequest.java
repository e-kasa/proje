package com.sedcore.product.model;

import java.util.List;
import com.sedcore.autoparts.model.OemNumberRequest;
import com.sedcore.autoparts.model.CrossReferenceRequest;
import com.sedcore.purchase.model.PurchaseRequest;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateProductRequest {
   private ProductRequest product;

    private List<ProductVariantRequest> variants;

    private List<OemNumberRequest> oemNumbers;

    private List<CrossReferenceRequest> crossReferences;

    private PurchaseRequest purchase;
}
