package com.sedcore.service.impl;

import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.StockCountItemRequest;
import com.sedcore.model.StockCountRequest;
import com.sedcore.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
        log.info("Stok sayimi baslatiliyor - Magaza: {}, Depo: {}, Kalem sayisi: {}",
                request.getStoreId(), request.getWarehouseId(), request.getItems().size());

        List<StockMovement> adjustments = new ArrayList<>();

        for (StockCountItemRequest item : request.getItems()) {

            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + item.getVariantId()));

            // Sistemdeki mevcut fiziksel stok
            int systemStock = getSystemStock(variant.getId(), request.getStoreId(), request.getWarehouseId());
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
                    .storeId(request.getStoreId())
                    .warehouseId(request.getWarehouseId())
                    .movementType(type)
                    .quantity(adjustQty)
                    .build();

            adjustments.add(stockMovementRepository.save(adjustment));

            log.info("Duzeltme hareketi - Variant: {}, Tip: {}, Miktar: {} (Sistem: {}, Sayim: {})",
                    variant.getSku(), type, adjustQty, systemStock, physicalCount);
        }

        log.info("Stok sayimi tamamlandi - Duzeltme yapilan kalem: {}", adjustments.size());
        return adjustments;
    }

    /**
     * inventory_view'dan mevcut fiziksel stok miktarını okur.
     * Kayıt yoksa 0 döner (hiç stok hareketi olmamış).
     */
    private int getSystemStock(String variantId, String storeId, String warehouseId) {
        return inventoryRepository
                .findByVariantIdAndStoreIdAndWarehouseId(variantId, storeId, warehouseId)
                .map(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                .orElse(0);
    }
}
