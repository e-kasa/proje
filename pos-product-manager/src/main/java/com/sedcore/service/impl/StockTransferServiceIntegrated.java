package com.sedcore.service.impl;

import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.StockTransferItemRequest;
import com.sedcore.model.StockTransferRequest;
import com.sedcore.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * ENTEGRE TRANSFER SERVICE
 * Depo/mağaza arası ürün transferi.
 *
 * Akış:
 * 1. StockTransfer kaydı oluştur
 * 2. Her kalem için stok yeterliliği kontrol et (kaynak depo)
 * 3. TRANSFER_OUT → kaynak depo/mağazadan düş
 * 4. TRANSFER_IN  → hedef depo/mağazaya ekle
 *
 * inventory_view bir DB view'ıdır (read-only).
 * Stok miktarı StockMovement kayıtlarından otomatik hesaplanır.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockTransferServiceIntegrated {

    private final StockTransferRepository stockTransferRepository;
    private final StockMovementRepository stockMovementRepository;
    private final ProductVariantRepository variantRepository;
    private final InventoryRepository inventoryRepository;

    @Transactional
    public StockTransfer createTransfer(StockTransferRequest request) {
        log.info("Transfer islemi baslatiliyor - Kaynak: {}/{} -> Hedef: {}/{}",
                request.getFromStoreId(), request.getFromWarehouseId(),
                request.getToStoreId(), request.getToWarehouseId());

        // 1. TRANSFER KAYDI OLUŞTUR
        StockTransfer transfer = new StockTransfer();
        transfer.setFromStoreId(request.getFromStoreId());
        transfer.setFromWarehouseId(request.getFromWarehouseId());
        transfer.setToStoreId(request.getToStoreId());
        transfer.setToWarehouseId(request.getToWarehouseId());

        transfer = stockTransferRepository.save(transfer);
        log.info("StockTransfer kaydedildi: ID={}", transfer.getId());

        // 2. HER KALEM İÇİN TRANSFER_OUT + TRANSFER_IN
        List<StockMovement> movements = new ArrayList<>();
        for (StockTransferItemRequest item : request.getItems()) {

            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + item.getVariantId()));

            // Stok yeterliliği kontrolü (kaynak depo)
            checkStockAvailability(variant.getId(),
                    request.getFromStoreId(), request.getFromWarehouseId(),
                    item.getQuantity());

            // TRANSFER_OUT — kaynaktan çıkar
            StockMovement outMovement = StockMovement.builder()
                    .variant(variant)
                    .storeId(request.getFromStoreId())
                    .warehouseId(request.getFromWarehouseId())
                    .movementType(StockMovementType.TRANSFER_OUT)
                    .quantity(item.getQuantity())
                    .transfer(transfer)
                    .build();
            movements.add(stockMovementRepository.save(outMovement));

            // TRANSFER_IN — hedefe ekle
            StockMovement inMovement = StockMovement.builder()
                    .variant(variant)
                    .storeId(request.getToStoreId())
                    .warehouseId(request.getToWarehouseId())
                    .movementType(StockMovementType.TRANSFER_IN)
                    .quantity(item.getQuantity())
                    .transfer(transfer)
                    .build();
            movements.add(stockMovementRepository.save(inMovement));

            log.info("Transfer hareketi: Variant={}, Miktar={}, {} -> {}",
                    variant.getSku(), item.getQuantity(),
                    request.getFromWarehouseId(), request.getToWarehouseId());
        }

        transfer.setMovements(movements);
        log.info("Transfer tamamlandi - Transfer ID: {}, Toplam hareket: {}",
                transfer.getId(), movements.size());
        return transfer;
    }

    /**
     * Stok yeterliliği kontrolü.
     * InventoryView bir DB view'ıdır (read-only) — sadece okuma yapılır.
     * Stok yoksa RuntimeException fırlatır.
     */
    private void checkStockAvailability(String variantId, String storeId,
                                        String warehouseId, Integer quantity) {
        InventoryView inventory = inventoryRepository
                .findByVariantIdAndStoreIdAndWarehouseId(variantId, storeId, warehouseId)
                .orElseThrow(() -> new RuntimeException(
                        "Stok bulunamadi - Variant: " + variantId
                        + ", Depo: " + warehouseId));

        int available = inventory.getPhysicalQuantity() != null ? inventory.getPhysicalQuantity() : 0;
        if (available < quantity) {
            throw new RuntimeException(String.format(
                    "Transfer icin stok yetersiz! Mevcut: %d, Istenen: %d (Variant: %s)",
                    available, quantity, variantId));
        }
    }
}
