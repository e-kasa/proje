package com.sedcore.inventory.repository;

import com.sedcore.inventory.entity.InventoryView;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryRepository extends BaseDaoRepository<InventoryView> {

    List<InventoryView> findByVariantId(String variantId);

    Optional<InventoryView> findByVariantIdAndLocationId(String variantId, String locationId);

    List<InventoryView> findByLocationId(String locationId);

    List<InventoryView> findByLocationType(String locationType);
}
