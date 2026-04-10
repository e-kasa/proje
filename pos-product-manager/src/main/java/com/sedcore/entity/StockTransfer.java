package com.sedcore.entity;

import java.util.List;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "stock_transfers")
@Getter @Setter
public class StockTransfer extends TOpenSimpleCompanyEntity {

    private String fromStoreId;
    private String fromWarehouseId;

    private String toStoreId;
    private String toWarehouseId;

    @OneToMany(mappedBy = "transfer", cascade = CascadeType.ALL)
    private List<StockMovement> movements;

    @Version
    private Long version;

}
