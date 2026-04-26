package com.sedcore.customer.entity;

import com.sedcore.autoparts.entity.Vehicle;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * CustomerVehicle — Bir müşterinin sahip olduğu/kayıtlı bir araç.
 *
 * <p>Sprint 9 (Opsiyon C) — parçacı sektör senaryosu için müşteri-plaka 1-N ilişki.
 * Aynı plaka iki farklı müşteride bağımsız kayıt olabilir
 * (UNIQUE: customer_id + plate_normalized + company_code).
 *
 * <p>Plaka normalizasyon: boşluk/çizgi temizle + uppercase
 * ("34 abc-123" → "34ABC123"). Search ve uniqueness için normalized kullanılır,
 * UI'da plate_display gösterilir (kullanıcı girişi).
 *
 * <p>Vehicle FK opsiyonel — mevcut Vehicle katalogundan seçilebilir veya
 * make/model/year freeform doldurulur (vehicle_id null).
 */
@Entity
@Table(name = "customer_vehicles",
       indexes = {
           @Index(name = "idx_cv_customer", columnList = "customer_id"),
           @Index(name = "idx_cv_plate_normalized", columnList = "plate_normalized"),
           @Index(name = "idx_cv_company", columnList = "company_code")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_cv_customer_plate_company",
                             columnNames = {"customer_id", "plate_normalized", "company_code"})
       })
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerVehicle extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    /** Kullanıcı girişi: "34 ABC 123" */
    @Column(name = "plate_display", nullable = false, length = 20)
    private String plateDisplay;

    /** Search/uniqueness: "34ABC123" — normalize edilmiş, indexed */
    @Column(name = "plate_normalized", nullable = false, length = 20)
    private String plateNormalized;

    /** Opsiyonel — Vehicle katalogundan seçildiyse FK; freeform ise null */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    private Vehicle vehicle;

    /** Vehicle FK null ise freeform fallback */
    @Column(length = 50)
    private String make;

    @Column(length = 100)
    private String model;

    @Column(name = "year_of_manufacture")
    private Integer yearOfManufacture;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    /** Optimistic lock — concurrent update koruması (project_ddl_strategy.md tuzak #3 için seed'de version=0 zorunlu) */
    @Version
    private Long version;

    /**
     * Plaka string'ini normalize eder: boşluk/çizgi temizle + uppercase.
     * "34 abc-123" → "34ABC123"
     */
    public static String normalize(String raw) {
        if (raw == null) return null;
        return raw.replaceAll("[\\s\\-]+", "").toUpperCase().trim();
    }
}
