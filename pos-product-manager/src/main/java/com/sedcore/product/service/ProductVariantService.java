package com.sedcore.product.service;

import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.model.ProductVariantResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface ProductVariantService extends BaseDbService<ProductVariant> {

    List<ProductVariantResponse> findByProductId(String productId);
}
