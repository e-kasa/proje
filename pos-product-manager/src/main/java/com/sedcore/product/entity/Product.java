package com.sedcore.product.entity;

import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.List;
import java.util.Map;

@Entity
@Table(name = "products")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Product extends TOpenSimpleCompanyEntity {


    @Column(nullable = false, length = 500)
    private String name;

    // SK (Stok Kodu)
    @Column(name = "sku", nullable = false, unique = true, length = 50)
    private String sku;

    @Column(name = "slug", nullable = true, unique = true, length = 50)
    private String slug;

    @Column(name = "category_id")
    private String categoryId;

    private String brand;
    private String unit;
    private String description;

    /**
     * Sektör: parcaci, giyim, genel
     * Flutter UI'da hangi alanların görüneceğini belirler
     */
    @Column(name = "sector", length = 20)
    private String sector;

    /**
     * Sektöre özel ek veriler (kumaş, sezon, araç grubu vb.)
     * JSONB olarak saklanır — şema değişikliği gerektirmez
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private Map<String, Object> metadata;

    @Builder.Default
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false; // soft silme

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private ProductStatus status;

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL)
    private List<ProductVariant> variants;

    @Version
    private Long version;
}