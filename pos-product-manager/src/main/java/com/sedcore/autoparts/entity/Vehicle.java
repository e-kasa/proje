package com.sedcore.autoparts.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "vehicles", indexes = {
        @Index(name = "idx_vehicle_make", columnList = "make"),
        @Index(name = "idx_vehicle_make_model", columnList = "make, model")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Vehicle extends TOpenSimpleCompanyEntity {

    @Column(name = "make", nullable = false, length = 100)
    private String make;

    @Column(name = "model", nullable = false, length = 100)
    private String model;

    @Column(name = "year_start")
    private Integer yearStart;

    @Column(name = "year_end")
    private Integer yearEnd;

    @Column(name = "engine_type", length = 100)
    private String engineType;

    @Column(name = "fuel_type", length = 50)
    private String fuelType;

    @Column(name = "body_type", length = 50)
    private String bodyType;

    @Column(name = "platform_code", length = 50)
    private String platformCode;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}
