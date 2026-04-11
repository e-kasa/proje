package com.sedcore.inventory.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Warehouse (Depo) entity.
 * warehouseId alanı StockMovement'da plain String olarak tutulur.
 * Bu entity depo listesini ve detaylarını yönetir.
 */
@Entity
@Table(name = "warehouses", indexes = {
        @Index(name = "idx_warehouse_code", columnList = "warehouse_code")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Warehouse extends TOpenSimpleCompanyEntity {

    @Column(name = "warehouse_code", nullable = false, unique = true, length = 50)
    private String code; // StockMovement.warehouseId ile eşleşen değer (ör. "WH-01")

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "store_code", length = 50)
    private String storeCode; // Hangi mağazaya bağlı (ör. "STORE-01")

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;
}
