package com.sedcore.product.repository;

import com.sedcore.product.entity.Brand;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BrandRepository extends BaseDaoRepository<Brand> {

    List<Brand> findByIsActiveTrueOrderByNameAsc();

    List<Brand> findAllByOrderByNameAsc();

    Optional<Brand> findByCode(String code);

    Optional<Brand> findByNameIgnoreCase(String name);
}
