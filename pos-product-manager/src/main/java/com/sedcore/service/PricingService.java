package com.sedcore.service;

import com.sedcore.entity.VariantPricing;
import com.sedcore.model.PricingResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface PricingService extends BaseDbService<VariantPricing> {

    List<PricingResponse> findByVariantId(String variantId);
}
