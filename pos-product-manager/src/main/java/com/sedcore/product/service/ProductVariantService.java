package com.sedcore.product.service;

import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.model.ProductVariantResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface ProductVariantService extends BaseDbService<ProductVariant> {

    List<ProductVariantResponse> findByProductId(String productId);

    /** Entity → Response dönüşümü — cross-service kullanım için */
    ProductVariantResponse mapToResponse(ProductVariant variant);
}
