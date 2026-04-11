package com.sedcore.autoparts.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import com.sedcore.product.entity.ProductVariant;

@Entity
@Table(name = "cross_references", indexes = {
        @Index(name = "idx_cross_ref_number", columnList = "cross_ref_number"),
        @Index(name = "idx_cross_ref_variant_id", columnList = "variant_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CrossReference extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(name = "cross_ref_number", nullable = false, length = 100)
    private String crossRefNumber;

    @Column(name = "cross_ref_brand", length = 100)
    private String crossRefBrand;

    @Column(name = "notes", length = 500)
    private String notes;
}
