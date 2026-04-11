package com.sedcore.product.repository;

import com.sedcore.product.entity.Unit;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UnitRepository extends BaseDaoRepository<Unit> {

    List<Unit> findByIsActiveTrueOrderByNameAsc();

    List<Unit> findAllByOrderByNameAsc();

    Optional<Unit> findByCodeIgnoreCase(String code);
}
