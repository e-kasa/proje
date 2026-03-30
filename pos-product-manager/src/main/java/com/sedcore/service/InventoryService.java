package com.sedcore.service;

import com.sedcore.entity.InventoryView;
import com.sedcore.model.InventoryResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;
import java.util.Optional;

public interface InventoryService extends BaseDbService<InventoryView> {

    /** Bir varyantın tüm depo/mağaza bazındaki stok kayıtları */
    List<InventoryResponse> getStockByVariant(String variantId);

    /** Bir varyantın toplam fiziksel stoku (tüm depolar toplamı) */
    int getTotalStock(String variantId);

    /** Belirli depo+mağazadaki stok */
    Optional<InventoryResponse> getStockByVariantAndLocation(String variantId, String storeId, String warehouseId);

    /**
     * Yeni bağımsız transaction'da varyantın stok kayıtlarını getirir.
     * Ana transaction'ın abort durumundan izole çalışır — transaction poisoning'e karşı güvenli.
     */
    List<InventoryView> findByVariantIdSafe(String variantId);
}
