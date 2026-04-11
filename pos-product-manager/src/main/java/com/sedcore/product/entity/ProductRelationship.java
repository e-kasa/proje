package com.sedcore.product.entity;

import com.sedcore.common.enums.ProductRelationType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Product Relationship Entity — Ürünler arasındaki ilişkiler (benzer, alternatif, tamamlayıcı)
 *
 * Yöneticiler tarafından manuel olarak oluşturulur.
 * POS'ta ürün önermeleri için kullanılır.
 */
@Entity
@Table(
    name = "product_relationship",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_product_relation_source_target_type",
            columnNames = {"source_product_id", "target_product_id", "relation_type"}
        )
    },
    indexes = {
        @Index(name = "idx_pr_source_product", columnList = "source_product_id"),
        @Index(name = "idx_pr_target_product", columnList = "target_product_id"),
        @Index(name = "idx_pr_is_active", columnList = "is_active"),
        @Index(name = "idx_pr_type", columnList = "relation_type"),
        @Index(name = "idx_pr_weight", columnList = "weight DESC")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductRelationship extends TOpenSimpleCompanyEntity {

    /**
     * Kaynak ürün ID — bu ürün seçildiğinde hangi ürünler önerilir?
     */
    @Column(name = "source_product_id", nullable = false, length = 255)
    private String sourceProductId;

    /**
     * Hedef ürün ID — önerilecek ürün
     */
    @Column(name = "target_product_id", nullable = false, length = 255)
    private String targetProductId;

    /**
     * İlişki tipi:
     * - SIMILAR: Benzer ürün (civata M10 → civata M12)
     * - ALTERNATIVE: Alternatif ürün (marka A → marka B aynı ürün)
     * - COMPLEMENTARY: Tamamlayıcı ürün (civata → civata pulu)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "relation_type", nullable = false, length = 50)
    private ProductRelationType relationType;

    /**
     * Ağırlık (1-10):
     * 1 = düşük öncelik
     * 10 = yüksek öncelik (sepete eklendiğinde ilk gösterilir)
     */
    @Builder.Default
    @Column(name = "weight", nullable = false)
    private Integer weight = 5;

    /**
     * Aktif/Pasif
     */
    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    /**
     * Tarafından oluşturuldu (admin username)
     */
    @Column(name = "created_by", length = 255)
    private String createdBy;

    /**
     * Tarafından güncellendi (admin username)
     */
    @Column(name = "updated_by", length = 255)
    private String updatedBy;

    /**
     * Validasyon: Kendi kendine ilişki olamaz
     */
    @PrePersist
    @PreUpdate
    private void validate() {
        if (sourceProductId != null && sourceProductId.equals(targetProductId)) {
            throw new IllegalArgumentException("Ürün kendisiyle ilişkilendirilemez!");
        }
    }
}
