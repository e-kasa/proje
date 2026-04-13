package com.sedcore.inventory.repository;

import com.sedcore.inventory.entity.StockLevel;
import com.towpen.base.db.repository.BaseDaoRepository;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockLevelRepository extends BaseDaoRepository<StockLevel> {

    /** Bir varyant + lokasyon için anlık stok (Hibernate filter otomatik company izolasyonu sağlar) */
    Optional<StockLevel> findByVariantIdAndLocationId(String variantId, String locationId);

    /** Pessimistic lock — eşzamanlı satış/transferde race condition önlenir */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT sl FROM StockLevel sl WHERE sl.variantId = :variantId AND sl.locationId = :locationId AND sl.companyCode = :companyCode")
    Optional<StockLevel> findByVariantIdAndLocationIdForUpdate(
            @Param("variantId") String variantId,
            @Param("locationId") String locationId,
            @Param("companyCode") String companyCode);

    /** Bir varyantın tüm lokasyonlardaki stoku */
    List<StockLevel> findByVariantId(String variantId);

    /** Bir lokasyonun tüm ürün stoklarını listele */
    List<StockLevel> findByLocationId(String locationId);

    /** Kritik stok: quantity <= minQuantity */
    @Query("SELECT sl FROM StockLevel sl WHERE sl.companyCode = :companyCode AND sl.quantity <= sl.minQuantity")
    List<StockLevel> findCriticalStocks(@Param("companyCode") String companyCode);

    /** Belirli lokasyonun kritik stokları */
    @Query("SELECT sl FROM StockLevel sl WHERE sl.companyCode = :companyCode AND sl.locationId = :locationId AND sl.quantity <= sl.minQuantity")
    List<StockLevel> findCriticalStocksByLocation(@Param("companyCode") String companyCode,
                                                   @Param("locationId") String locationId);

    /** Tüm firma stoğunun toplam miktarı (tüm lokasyonlar) */
    @Query("SELECT COALESCE(SUM(sl.quantity), 0) FROM StockLevel sl WHERE sl.companyCode = :companyCode AND sl.variantId = :variantId")
    Integer sumQuantityByVariant(@Param("companyCode") String companyCode,
                                  @Param("variantId") String variantId);

    /** Atomic increment — Spring Data JPA @Modifying */
    @Modifying
    @Query("UPDATE StockLevel sl SET sl.quantity = sl.quantity + :delta WHERE sl.variantId = :variantId AND sl.locationId = :locationId AND sl.companyCode = :companyCode")
    int incrementQuantity(@Param("variantId") String variantId,
                          @Param("locationId") String locationId,
                          @Param("companyCode") String companyCode,
                          @Param("delta") int delta);
}
