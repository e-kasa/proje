package com.sedcore.repository;

import com.sedcore.entity.Warehouse;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WarehouseRepository extends BaseDaoRepository<Warehouse> {

    Optional<Warehouse> findByCode(String code);

    List<Warehouse> findByIsActive(Boolean isActive);

    List<Warehouse> findByStoreCode(String storeCode);
}
