package com.sedcore.inventory.service.impl;

import com.sedcore.inventory.entity.InventoryView;
import com.sedcore.inventory.model.InventoryResponse;
import com.sedcore.inventory.repository.InventoryRepository;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * InventoryService — InventoryView (DB view) üzerinden stok okuma.
 *
 * SADECE OKUMA yapar. Stok değiştirmek için StockMovement kaydı oluştur.
 *
 * Kullanım yerleri:
 *   - Ürün detay/liste → stok miktarı gösterimi
 *   - POS satış öncesi → yeterli stok var mı kontrolü
 *   - Dashboard → düşük stok alarmları
 */
@Service
@Slf4j
@Transactional(readOnly = true)
public class InventoryService extends BaseDbServiceImp<InventoryRepository, InventoryView>
        implements com.sedcore.service.InventoryService {

    @Override
    public Class<?> getDTOClassForService() {
        return InventoryResponse.class;
    }

    /**
     * Bir varyantın tüm depo/mağaza bazındaki stok kayıtları.
     * Örn: 3 depoda stok varsa 3 adet InventoryResponse döner.
     */
    @Override
    public List<InventoryResponse> getStockByVariant(String variantId) {
        return dao.findByVariantId(variantId).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Bir varyantın TÜM depolardaki toplam fiziksel stoku.
     * Flutter ürün kartı için: "Toplam X adet"
     */
    @Override
    public int getTotalStock(String variantId) {
        return dao.findByVariantId(variantId).stream()
                .mapToInt(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                .sum();
    }

    /**
     * Belirli depo + mağazadaki stok.
     * POS satışta: "Bu mağazada/depoda yeterli stok var mı?"
     */
    @Override
    public Optional<InventoryResponse> getStockByVariantAndLocation(
            String variantId, String storeId, String warehouseId) {
        return dao.findByVariantIdAndStoreIdAndWarehouseId(variantId, storeId, warehouseId)
                .map(this::toResponse);
    }

    /**
     * Bağımsız (REQUIRES_NEW) transaction'da varyant stok kayıtlarını çeker.
     * ProductServiceImpl'in mapVariantToResponse() metodu bu metodu çağırmalı;
     * böylece ana transaction'ın abort durumu buraya sızmaz.
     */
    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW, readOnly = true)
    public List<InventoryView> findByVariantIdSafe(String variantId) {
        return dao.findByVariantId(variantId);
    }

    // -------------------------------------------------------------------------

    private InventoryResponse toResponse(InventoryView iv) {
        return InventoryResponse.builder()
                .id(iv.getId())
                .variantId(iv.getVariantId())
                .storeId(iv.getStoreId())
                .warehouseId(iv.getWarehouseId())
                .physicalQuantity(iv.getPhysicalQuantity())
                .build();
    }
}
