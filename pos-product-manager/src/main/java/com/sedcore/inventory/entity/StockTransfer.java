package com.sedcore.inventory.entity;

import java.util.List;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.Setter;

/**
 * StockTransfer — Lokasyonlar arası stok transferi.
 *
 * fromLocationId → toLocationId arasındaki hareket.
 * Her iki taraf da STORE veya WAREHOUSE olabilir.
 * locationType alanları: "STORE" veya "WAREHOUSE"
 */
@Entity
@Table(name = "stock_transfers")
@Getter @Setter
public class StockTransfer extends TOpenSimpleCompanyEntity {

    /** Kaynak lokasyon kodu (Store.code veya Warehouse.code) */
    @Column(name = "from_location_id", length = 50)
    private String fromLocationId;

    /** Kaynak lokasyon tipi: "STORE" veya "WAREHOUSE" */
    @Column(name = "from_location_type", length = 10)
    private String fromLocationType;

    /** Hedef lokasyon kodu (Store.code veya Warehouse.code) */
    @Column(name = "to_location_id", length = 50)
    private String toLocationId;

    /** Hedef lokasyon tipi: "STORE" veya "WAREHOUSE" */
    @Column(name = "to_location_type", length = 10)
    private String toLocationType;

    @Column(length = 500)
    private String notes;

    @OneToMany(mappedBy = "transfer", cascade = CascadeType.ALL)
    private List<StockMovement> movements;

    @Version
    private Long version;
}
