package com.sedcore.product.repository;

import com.sedcore.inventory.entity.Site;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductVariantAttributeValueRepository extends BaseDaoRepository<Site> {
}
