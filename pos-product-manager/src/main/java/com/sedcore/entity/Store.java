package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Store (Mağaza) entity.
 * storeId alanı StockMovement, Sale, Purchase'da plain String olarak tutulur.
 * Bu entity mağaza listesini ve detaylarını yönetir.
 */
@Entity
@Table(name = "stores", indexes = {
        @Index(name = "idx_store_code", columnList = "store_code")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Store extends TOpenSimpleCompanyEntity {

    @Column(name = "store_code", nullable = false, unique = true, length = 50)
    private String code; // StockMovement.storeId ile eşleşen değer (ör. "STORE-01")

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;
}
