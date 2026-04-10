package com.sedcore.repository;

import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockMovementRepository extends BaseDaoRepository<StockMovement> {

    // Purchase ilişkisi üzerinden (purchase.id navigasyonu)
    List<StockMovement> findByPurchaseId(String purchaseId);

    // Variant + Store kombine filtre (company scoped) — JOIN FETCH ile LAZY ilişkiler yüklenir
    @Query("SELECT sm FROM StockMovement sm JOIN FETCH sm.variant v LEFT JOIN FETCH v.product LEFT JOIN FETCH sm.sale LEFT JOIN FETCH sm.purchase LEFT JOIN FETCH sm.transfer WHERE v.id = :variantId AND sm.storeId = :storeId AND sm.companyCode = :companyCode ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantIdAndStoreId(@Param("variantId") String variantId, @Param("storeId") String storeId, @Param("companyCode") String companyCode);

    // Variant hareketleri — JOIN FETCH ile controller'da LazyInitializationException önlenir
    @Query("SELECT sm FROM StockMovement sm JOIN FETCH sm.variant v LEFT JOIN FETCH v.product LEFT JOIN FETCH sm.sale LEFT JOIN FETCH sm.purchase LEFT JOIN FETCH sm.transfer WHERE v.id = :variantId AND sm.companyCode = :companyCode ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantId(@Param("variantId") String variantId, @Param("companyCode") String companyCode);

    // Eski imza (deprecated - backward compatibility için)
    @Query("SELECT sm FROM StockMovement sm JOIN FETCH sm.variant v LEFT JOIN FETCH v.product LEFT JOIN FETCH sm.sale LEFT JOIN FETCH sm.purchase LEFT JOIN FETCH sm.transfer WHERE v.id = :variantId ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantIdWithoutCompanyFilter(@Param("variantId") String variantId);

    // Satış hareketleri (sale.id navigasyonu - company scoped)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.companyCode = :companyCode")
    List<StockMovement> findBySaleId(@Param("saleId") String saleId, @Param("companyCode") String companyCode);

    // Transfer hareketleri (transfer.id navigasyonu)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.transfer.id = :transferId")
    List<StockMovement> findByTransferId(@Param("transferId") String transferId);

    // Mağaza bazlı hareketler (doğrudan String field)
    List<StockMovement> findByStoreId(String storeId);

    // Depo bazlı hareketler (doğrudan String field)
    List<StockMovement> findByWarehouseId(String warehouseId);

    // Satış + hareket tipi (iptal/iade doğrulama için - company scoped)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.movementType = :movementType AND sm.companyCode = :companyCode")
    List<StockMovement> findBySaleIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("movementType") StockMovementType movementType,
            @Param("companyCode") String companyCode);

    // Varyant + satış (iade miktarı hesaplama için)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.variant.id = :variantId AND sm.movementType = :movementType")
    List<StockMovement> findBySaleIdAndVariantIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType);

    // Belirli varyant + hareket tipi için ilk kaydı döner (store/warehouse fallback için)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.variant.id = :variantId AND sm.movementType = :movementType ORDER BY sm.createTime ASC")
    Optional<StockMovement> findFirstByVariantIdAndMovementType(
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType);

    // Birlikte satılan ürünleri getir (Recommendation için)
    // Aynı satışta yer alan diğer ürünleri sıklığa göre sırala
    // Company scoping explicit olarak uygulanır
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
