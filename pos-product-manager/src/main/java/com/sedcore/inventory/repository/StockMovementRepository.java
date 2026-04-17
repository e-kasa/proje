package com.sedcore.inventory.repository;

import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.common.enums.StockMovementType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockMovementRepository extends BaseDaoRepository<StockMovement> {

    List<StockMovement> findByPurchaseId(String purchaseId);

    /** Variant + lokasyon bazlı hareketler (audit / rapor) */
    @Query("SELECT sm FROM StockMovement sm JOIN FETCH sm.variant v LEFT JOIN FETCH v.product LEFT JOIN FETCH sm.sale LEFT JOIN FETCH sm.purchase LEFT JOIN FETCH sm.transfer WHERE v.id = :variantId AND sm.locationId = :locationId AND sm.companyCode = :companyCode ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantIdAndLocationId(
            @Param("variantId") String variantId,
            @Param("locationId") String locationId,
            @Param("companyCode") String companyCode);

    /** Variant'ın tüm lokasyonlardaki hareketleri */
    @Query("SELECT sm FROM StockMovement sm JOIN FETCH sm.variant v LEFT JOIN FETCH v.product LEFT JOIN FETCH sm.sale LEFT JOIN FETCH sm.purchase LEFT JOIN FETCH sm.transfer WHERE v.id = :variantId AND sm.companyCode = :companyCode ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantId(
            @Param("variantId") String variantId,
            @Param("companyCode") String companyCode);

    /** Satış hareketleri */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.companyCode = :companyCode")
    List<StockMovement> findBySaleId(
            @Param("saleId") String saleId,
            @Param("companyCode") String companyCode);

    /** Transfer hareketleri */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.transfer.id = :transferId")
    List<StockMovement> findByTransferId(@Param("transferId") String transferId);

    /** Lokasyon bazlı hareketler */
    List<StockMovement> findByLocationId(String locationId);

    /** Satış + hareket tipi */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.movementType = :movementType AND sm.companyCode = :companyCode")
    List<StockMovement> findBySaleIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("movementType") StockMovementType movementType,
            @Param("companyCode") String companyCode);

    /** Varyant + satış + hareket tipi (iade miktarı hesaplama) */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.variant.id = :variantId AND sm.movementType = :movementType")
    List<StockMovement> findBySaleIdAndVariantIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType);

    /** İlk PURCHASE_IN kaydı (fallback lokasyon tespiti) */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.variant.id = :variantId AND sm.movementType = :movementType ORDER BY sm.createTime ASC")
    Optional<StockMovement> findFirstByVariantIdAndMovementType(
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType);

    /** En son PURCHASE_IN kaydı — doküman analizinde son alış fiyatını enrichment için. */
    @Query("SELECT sm FROM StockMovement sm WHERE sm.variant.id = :variantId AND sm.movementType = :movementType ORDER BY sm.createTime DESC")
    List<StockMovement> findLastByVariantIdAndMovementType(
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType,
            Pageable pageable);

    /** Birlikte satılan ürünler — Recommendation engine */
    @Query(value = """
            SELECT p.id, p.name, p.sku, pv.id as variantId, COUNT(*) as frequency
            FROM stock_movements sm1
            JOIN stock_movements sm2 ON sm1.sale_id = sm2.sale_id AND sm1.id != sm2.id
            JOIN product_variant pv ON sm2.variant_id = pv.id
            JOIN product p ON pv.product_id = p.id
            WHERE sm1.variant_id IN (:variantIds)
              AND sm1.movement_type = 'SALE_OUT'
              AND sm2.movement_type = 'SALE_OUT'
              AND sm1.company_code = :companyCode
              AND sm2.company_code = :companyCode
              AND p.is_deleted = false
            GROUP BY p.id, p.name, p.sku, pv.id
            ORDER BY frequency DESC
            """, nativeQuery = true)
    List<Object[]> findFrequentlyBoughtTogether(
            @Param("variantIds") List<String> variantIds,
            @Param("companyCode") String companyCode,
            Pageable pageable);
}
