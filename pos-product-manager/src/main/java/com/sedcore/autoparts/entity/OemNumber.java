package com.sedcore.autoparts.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "oem_numbers", indexes = {
        @Index(name = "idx_oem_number", columnList = "oem_number"),
        @Index(name = "idx_oem_variant_id", columnList = "variant_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OemNumber extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @Column(name = "oem_number", nullable = false, length = 100)
    private String oemNumber;

    @Column(name = "manufacturer", length = 100)
    private String manufacturer;

    @Builder.Default
    @Column(name = "is_primary", nullable = false)
    private Boolean isPrimary = false;
}
