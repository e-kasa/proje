package com.sedcore.inventory.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.inventory.model.StockCountItemRequest;
import com.sedcore.inventory.model.StockCountRequest;
import com.sedcore.inventory.repository.InventoryRepository;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.inventory.repository.StockMovementRepository;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.security.ISessionInstanceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * STOK SAYIM / DÜZELTME SERVICE
 *
 * Mantık:
 * - Sayım yapılır, fiili miktar sisteme girilir.
 * - Sistem stoku (inventory_view.physicalQuantity) ile karşılaştırılır.
 * - Fark varsa düzeltme hareketi yazılır:
 *     fiili > sistem  → ADJUSTMENT_IN  (stok fazlası - sisteme ekle)
 *     fiili < sistem  → ADJUSTMENT_OUT (stok eksiği  - sistemden düş)
 *     fiili = sistem  → hareket yok    (fark yok)
 *
 * inventory_view bir DB view'ıdır (read-only).
 * Stok miktarı StockMovement kayıtlarından otomatik hesaplanır.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockCountServiceIntegrated {

    private final StockMovementRepository stockMovementRepository;
    private final ProductVariantRepository variantRepository;
    private final InventoryRepository inventoryRepository;
    @Autowired private ISessionInstanceService sessionInstanceService;

    /**
     * Stok sayım işlemini gerçekleştirir.
     * Her kalem için:
     * - Sistemdeki stok inventory_view'dan okunur.
     * - Farka göre ADJUSTMENT_IN veya ADJUSTMENT_OUT yazılır.
     *
     * @return yazılan StockMovement listesi (fark olmayan kalemler dahil değil)
     */
    @Transactional
    public List<StockMovement> processStockCount(StockCountRequest request) {
        log.info("Stok sayimi baslatiliyor - Lokasyon: {}, Kalem sayisi: {}",
                request.getLocationId(), request.getItems().size());

        List<StockMovement> adjustments = new ArrayList<>();

        for (StockCountItemRequest item : request.getItems()) {

            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + item.getVariantId()));

            // Sistemdeki mevcut fiziksel stok
            int systemStock = getSystemStock(variant.getId(), request.getLocationId());
            int physicalCount = item.getPhysicalCount();
            int diff = physicalCount - systemStock;

            if (diff == 0) {
                log.info("Fark yok - Variant: {}, Sistem: {}, Sayim: {}",
                        variant.getSku(), systemStock, physicalCount);
                continue;
            }

            StockMovementType type = diff > 0 ? StockMovementType.ADJUSTMENT_IN
                                               : StockMovementType.ADJUSTMENT_OUT;
            int adjustQty = Math.abs(diff);

            StockMovement adjustment = StockMovement.builder()
                    .variant(variant)
                    .locationId(request.getLocationId())
                    .locationType(request.getLocationType() != null ? request.getLocationType() : "STORE")
                    .movementType(type)
                    .quantity(adjustQty)
                    .build();

            adjustments.add(prepareAndSave(stockMovementRepository, adjustment));

            log.info("Duzeltme hareketi - Variant: {}, Lokasyon: {}, Tip: {}, Miktar: {} (Sistem: {}, Sayim: {})",
                    variant.getSku(), request.getLocationId(), type, adjustQty, systemStock, physicalCount);
        }

        log.info("Stok sayimi tamamlandi - Duzeltme yapilan kalem: {}", adjustments.size());
        return adjustments;
    }

    /**
     * inventory_view'dan mevcut fiziksel stok miktarını okur.
     * Kayıt yoksa 0 döner (hiç stok hareketi olmamış).
     */
    private int getSystemStock(String variantId, String locationId) {
        return inventoryRepository
                .findByVariantIdAndLocationId(variantId, locationId)
                .map(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                .orElse(0);
    }

    /**
     * Herhangi bir entity için audit alanları + companyCode set ederek kaydeder.
     */
    private <E extends TOpenSimpleCompanyEntity> E prepareAndSave(
            org.springframework.data.repository.CrudRepository<E, String> repo, E entity) {
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) {
            entity.setCompanyCode(companyCode);
        }
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(java.util.Calendar.getInstance().getTime());
        }
        if (entity.getCreateUser() == null || entity.getCreateUser().isBlank()) {
            String userCode = null;
            try { userCode = sessionInstanceService.getUserCode(); } catch (Exception ignored) {}
            entity.setCreateUser(userCode != null && !userCode.isBlank() ? userCode : "SYSTEM");
        }
        return repo.save(entity);
    }
}
