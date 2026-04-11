package com.sedcore.product.service.impl;

import com.sedcore.product.entity.VariantPricing;
import com.sedcore.product.model.PricingResponse;
import com.sedcore.product.repository.PricingRepository;
import com.sedcore.product.service.PricingService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class PricingServiceImpl extends BaseDbServiceImp<PricingRepository, VariantPricing> implements PricingService {

    @Override
    public Class<?> getDTOClassForService() {
        return PricingResponse.class;
    }

    public PricingResponse mapToResponse(VariantPricing pricing) {
        PricingResponse dto = toDTO(pricing);
        // Variant FK ilişkisinden gelen alanlar — BeanUtils doğrudan kopyalamaz
        if (pricing.getVariant() != null) {
            dto.setVariantId(pricing.getVariant().getId());
            dto.setVariantSku(pricing.getVariant().getSku());
        }
        return dto;
    }

    @Transactional(readOnly = true)
    public List<PricingResponse> findByVariantId(String variantId) {
        return dao.findByVariantId(variantId).stream()
                .map(this::mapToResponse)
                .toList();
    }
}
