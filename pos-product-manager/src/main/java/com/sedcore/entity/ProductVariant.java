package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "product_variants")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProductVariant extends TOpenSimpleCompanyEntity {



    // SK (Stok Kodu)
    @Column(name = "sku", nullable = false, unique = true, length = 50)
    private String sku;

    @Column(name = "slug", nullable = true, unique = true, length = 50)
    private String slug;
    private String name;

    @Column(precision = 15, scale = 2)
    private BigDecimal additionalPrice;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, String> attributes;

    @ManyToOne
    @JoinColumn(name = "product_id")
    private Product product;

    @Builder.Default
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false; // soft silme


    /**
     * Minimum stok seviyesi — bu seviyenin altında stok varsa Flutter düşük stok uyarısı verir.
     * Stok hareketi değil, sabit eşik değeridir. Default: 10.
     */
    @Builder.Default
    @Column(name = "min_stock_level")
    private Integer minStockLevel = 10;

    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<StockMovement> stockMovement;


    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<VariantPricing> variantPricings;


    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<Barcode> barcodes;

    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<OemNumber> oemNumbers;

    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<CrossReference> crossReferences;

    @OneToMany(mappedBy = "variant", cascade = CascadeType.ALL)
    private List<VehicleCompatibility> vehicleCompatibilities;

    @Column(name = "shelf_location_code", length = 50)
    private String shelfLocationCode;
}