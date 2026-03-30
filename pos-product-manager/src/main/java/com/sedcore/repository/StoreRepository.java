package com.sedcore.repository;

import com.sedcore.entity.Store;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends BaseDaoRepository<Store> {

    Optional<Store> findByCode(String code);

    List<Store> findByIsActive(Boolean isActive);
}
