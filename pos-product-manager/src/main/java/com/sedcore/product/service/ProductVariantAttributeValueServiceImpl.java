package com.sedcore.product.service;

import com.sedcore.inventory.entity.Site;
import com.sedcore.product.repository.ProductVariantAttributeValueRepository;
import com.towpen.base.security.BaseDbServiceImp;
import org.springframework.stereotype.Service;

@Service
public class ProductVariantAttributeValueServiceImpl extends BaseDbServiceImp<ProductVariantAttributeValueRepository, Site> implements ProductVariantAttributeValueService {
    @Override
    public Class<?> getDTOClassForService() {
        return null;
    }
}
