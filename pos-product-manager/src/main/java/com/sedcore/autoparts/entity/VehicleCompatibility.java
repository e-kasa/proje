package com.sedcore.autoparts.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "vehicle_compatibilities",
        uniqueConstraints = @UniqueConstraint(columnNames = {"variant_id", "vehicle_id"}),
        indexes = {
                @Index(name = "idx_vc_variant_id", columnList = "variant_id"),
                @Index(name = "idx_vc_vehicle_id", columnList = "vehicle_id")
        })
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VehicleCompatibility extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @Column(name = "notes", length = 500)
    private String notes;

    @Builder.Default
    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified = false;
}
