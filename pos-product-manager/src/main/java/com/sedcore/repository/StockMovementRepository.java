package com.sedcore.repository;

import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StockMovementRepository extends BaseDaoRepository<StockMovement> {

    // Purchase ilişkisi üzerinden (purchase.id navigasyonu)
    List<StockMovement> findByPurchaseId(String purchaseId);

    // Variant + Store kombine filtre
    List<StockMovement> findByVariantIdAndStoreId(String variantId, String storeId);

    // Variant hareketleri (variant.id navigasyonu — @Query ile güvenli)
    // createTime base entity'de (TOpenSimpleCompanyEntity) tanımlı
    @Query("SELECT sm FROM StockMovement sm WHERE sm.variant.id = :variantId ORDER BY sm.createTime DESC")
    List<StockMovement> findByVariantId(@Param("variantId") String variantId);

    // Satış hareketleri (sale.id navigasyonu)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId")
    List<StockMovement> findBySaleId(@Param("saleId") String saleId);

    // Transfer hareketleri (transfer.id navigasyonu)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.transfer.id = :transferId")
    List<StockMovement> findByTransferId(@Param("transferId") String transferId);

    // Mağaza bazlı hareketler (doğrudan String field)
    List<StockMovement> findByStoreId(String storeId);

    // Depo bazlı hareketler (doğrudan String field)
    List<StockMovement> findByWarehouseId(String warehouseId);

    // Satış + hareket tipi (iptal/iade doğrulama için)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.movementType = :movementType")
    List<StockMovement> findBySaleIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("movementType") StockMovementType movementType);

    // Varyant + satış (iade miktarı hesaplama için)
    @Query("SELECT sm FROM StockMovement sm WHERE sm.sale.id = :saleId AND sm.variant.id = :variantId AND sm.movementType = :movementType")
    List<StockMovement> findBySaleIdAndVariantIdAndMovementType(
            @Param("saleId") String saleId,
            @Param("variantId") String variantId,
            @Param("movementType") StockMovementType movementType);
}
