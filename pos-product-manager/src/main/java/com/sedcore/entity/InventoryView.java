package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Immutable;

@Entity
@Table(name = "inventory_view")
@Immutable
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryView extends TOpenSimpleCompanyEntity {

  
     @Column(name = "variant_id")
    private String variantId;

    private String storeId;
    private String warehouseId;

    private Integer physicalQuantity;
}