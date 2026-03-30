package com.sedcore.entity;

import com.sedcore.enums.BarcodeType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

import java.util.Date;

@Entity
@Table(name = "barcodes")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Barcode extends TOpenSimpleCompanyEntity {

    @Column(name = "barcode_code", nullable = false, length = 200)
    @Comment("Barkod Kodu")
    private String barcodeCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "barcode_type", nullable = false, length = 20)
    @Comment("Barkod Tipi - EAN13, UPC, QR_CODE")
    private BarcodeType barcodeType;

    @Column(name = "is_primary")
    @Comment("Ana Barkod mu?")
    @Builder.Default
    private Boolean isPrimary = false;

    @Column(name = "is_active")
    @Comment("Aktif mi?")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "usage_count")
    @Comment("Kullanım Sayısı")
    @Builder.Default
    private Long usageCount = 0L;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "last_used_at")
    @Comment("Son Kullanım Zamanı")
    private Date lastUsedAt;

    @Column(name = "notes", length = 1000)
    @Comment("Notlar")
    private String notes;

    @ManyToOne
    @JoinColumn(name = "variant_id")
    private ProductVariant variant;
}