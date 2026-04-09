package com.sedcore.service.impl;

import com.sedcore.entity.Barcode;
import com.sedcore.entity.ProductVariant;
import com.sedcore.entity.VariantPricing;
import com.sedcore.model.BarcodeResponse;
import com.sedcore.model.ProductVariantResponse;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.service.ProductVariantService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
@Transactional
public class ProductVariantServiceImpl extends BaseDbServiceImp<ProductVariantRepository, ProductVariant>
        implements ProductVariantService {

    @Override
    public Class<?> getDTOClassForService() {
        return ProductVariantResponse.class;
    }

    public ProductVariantResponse mapToResponse(ProductVariant variant) {
        List<BarcodeResponse> barcodeResponses = new ArrayList<>();
        if (variant.getBarcodes() != null) {
            for (Barcode b : variant.getBarcodes()) {
                if (Boolean.TRUE.equals(b.getIsActive())) {
                    barcodeResponses.add(BarcodeResponse.builder()
                            .id(b.getId())
                            .barcodeCode(b.getBarcodeCode())
                            .barcodeType(b.getBarcodeType() != null ? b.getBarcodeType().name() : null)
                            .isPrimary(b.getIsPrimary())
                            .isActive(b.getIsActive())
                            .usageCount(b.getUsageCount())
                            .build());
                }
            }
        }

        BigDecimal salePrice = null;
        if (variant.getVariantPricings() != null && !variant.getVariantPricings().isEmpty()) {
            VariantPricing latest = variant.getVariantPricings().get(variant.getVariantPricings().size() - 1);
            salePrice = latest.getSalePrice();
        }

        return ProductVariantResponse.builder()
                .id(variant.getId())
                .sku(variant.getSku())
                .name(variant.getName())
                .additionalPrice(variant.getAdditionalPrice())
                .salePrice(salePrice)
                .attributes(variant.getAttributes())
                .barcodes(barcodeResponses)
                .inventory(null)
                .build();
    }

    @Transactional(readOnly = true)
    public List<ProductVariantResponse> findByProductId(String productId) {
        return dao.findByProductIdAndIsDeleted(productId, false).stream()
                .map(this::mapToResponse)
                .toList();
    }
}
