package com.sedcore.inventory.repository;

import com.sedcore.inventory.entity.Store;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends BaseDaoRepository<Store> {

    Optional<Store> findByCode(String code);

    Optional<Store> findByIdAndCompanyCode(String id, String companyCode);

    List<Store> findByIsActive(Boolean isActive);
}
