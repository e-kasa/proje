package com.sedcore.service;

import com.sedcore.entity.ProductVariant;
import com.sedcore.model.ProductVariantResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface ProductVariantService extends BaseDbService<ProductVariant> {

    List<ProductVariantResponse> findByProductId(String productId);
}
