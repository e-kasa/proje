package com.sedcore.entity;

import com.sedcore.enums.ProductStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

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

    @Builder.Default
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false; // soft silme

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private ProductStatus status;

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL)
    private List<ProductVariant> variants;
}