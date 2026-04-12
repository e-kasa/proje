package com.sedcore.product.service.impl;

import com.sedcore.product.entity.Barcode;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.entity.VariantPricing;
import com.sedcore.product.model.BarcodeResponse;
import com.sedcore.product.model.ProductVariantResponse;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.product.service.ProductVariantService;
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
        // toDTO(): id, sku, name, additionalPrice, status, imageUrl, attributes kopyalanır
        ProductVariantResponse dto = toDTO(variant);

        // barcodes — LAZY koleksiyon, BeanUtils kopyalamaz; enum→String dönüşümü de gerekir
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
        dto.setBarcodes(barcodeResponses);

        // salePrice — VariantPricing ilişkisinden hesaplanan alan
        if (variant.getVariantPricings() != null && !variant.getVariantPricings().isEmpty()) {
            List<VariantPricing> pricings = variant.getVariantPricings();
            VariantPricing latest = pricings.get(pricings.size() - 1);
            dto.setSalePrice(latest.getSalePrice());
        }

        return dto;
    }

    @Transactional(readOnly = true)
    public List<ProductVariantResponse> findByProductId(String productId) {
        return dao.findByProductIdAndIsDeleted(productId, false).stream()
                .map(this::mapToResponse)
                .toList();
    }
}
