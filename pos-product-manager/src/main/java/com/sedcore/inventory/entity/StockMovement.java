package com.sedcore.inventory.entity;

import com.sedcore.common.enums.StockMovementType;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.sales.entity.Sale;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "stock_movements",
       indexes = {
           @Index(name = "idx_sm_variant", columnList = "variant_id"),
           @Index(name = "idx_sm_store", columnList = "store_id")
       }
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StockMovement extends TOpenSimpleCompanyEntity{
 
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(nullable = true)
    private String storeId;

    @Column(nullable = true)
    private String warehouseId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StockMovementType movementType;
    // IN, OUT

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", precision = 15, scale = 2)
    private java.math.BigDecimal unitPrice;

    // 🔗 KAYNAK BELGELER
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchase_id")
    private Purchase purchase;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transfer_id")
    private StockTransfer transfer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id")
    private Sale sale;

    @Version
    private Long version;

}
