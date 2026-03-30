package com.sedcore.repository;

import com.sedcore.entity.InventoryView;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryRepository extends BaseDaoRepository<InventoryView> {

    List<InventoryView> findByVariantId(String variantId);

    Optional<InventoryView> findByVariantIdAndStoreIdAndWarehouseId(
            String variantId, String storeId, String warehouseId);

    List<InventoryView> findByStoreId(String storeId);

    List<InventoryView> findByWarehouseId(String warehouseId);
}
