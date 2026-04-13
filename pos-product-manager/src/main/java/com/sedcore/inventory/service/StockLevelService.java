package com.sedcore.inventory.service;

import com.sedcore.inventory.entity.StockLevel;

import java.util.List;
import java.util.Map;

public interface StockLevelService {

    /** Stok ekle — alım, transfer_in, iade_in. Kayıt yoksa oluşturur (upsert). */
    StockLevel addStock(String variantId, String locationId, String locationType, int qty);

    /**
     * Stok düş — satış, transfer_out, iade_out.
     * Yetersiz stok varsa BusinessException fırlatır.
     */
    StockLevel deductStock(String variantId, String locationId, int qty);

    /** Stok miktarını belirli değere set et — sayım düzeltmesi */
    StockLevel setStock(String variantId, String locationId, String locationType, int absoluteQty);

    /** Anlık stok miktarı — null dönebilir (stok kaydı henüz yoksa) */
    Integer getQuantity(String variantId, String locationId);

    /** Bir varyantın tüm lokasyonlardaki stoğu */
    List<StockLevel> getByVariant(String variantId);

    /** Bir lokasyonun tüm ürün stoklarını listele */
    List<StockLevel> getByLocation(String locationId);

    /** Firma genelinde kritik stok listesi (quantity <= minQuantity) */
    List<StockLevel> getCriticalStocks(String companyCode);

    /** Bir varyantın tüm lokasyonlardaki toplam stoku */
    int getTotalQuantity(String variantId);

    /** Min quantity güncelle (per-lokasyon alarm eşiği) */
    StockLevel updateMinQuantity(String variantId, String locationId, int minQuantity);

    /** Lokasyon bazlı stok özeti — admin dashboard için */
    Map<String, Integer> getLocationSummary(String locationId);
}
