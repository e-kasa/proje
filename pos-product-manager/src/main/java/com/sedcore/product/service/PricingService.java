package com.sedcore.product.service;

import com.sedcore.product.entity.VariantPricing;
import com.sedcore.product.model.PricingResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface PricingService extends BaseDbService<VariantPricing> {

    List<PricingResponse> findByVariantId(String variantId);
}
