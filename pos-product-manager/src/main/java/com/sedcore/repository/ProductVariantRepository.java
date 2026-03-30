package com.sedcore.repository;

import com.sedcore.entity.ProductVariant;
import com.towpen.base.db.repository.BaseDaoRepository;
import jakarta.validation.constraints.NotBlank;

import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductVariantRepository extends BaseDaoRepository<ProductVariant> {
    Optional<ProductVariant> findByIdAndIsDeleted(String id, Boolean isDeleted);

    @Query("Select pv from ProductVariant pv where pv.sku=:sku and pv.isDeleted=:isDeleted")
    Optional<ProductVariant> findBySkuAndIsDeleted(String sku, Boolean isDeleted);

    List<ProductVariant> findByProductIdAndIsDeleted(
            String productId, Boolean isDeleted
    );

    boolean existsBySkuAndIdNot(String sku, String id);
}
