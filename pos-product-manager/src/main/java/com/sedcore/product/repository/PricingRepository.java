package com.sedcore.product.repository;

import com.sedcore.product.entity.VariantPricing;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PricingRepository extends BaseDaoRepository<VariantPricing> {

    @Query("SELECT vp FROM VariantPricing vp WHERE vp.variant.id = :variantId ORDER BY vp.validFrom DESC")
    List<VariantPricing> findByVariantId(@Param("variantId") String variantId);
}
