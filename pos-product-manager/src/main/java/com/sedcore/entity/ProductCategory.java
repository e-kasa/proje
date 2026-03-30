package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

/**
 * Ürün-Kategori İlişki Tablosu
 * Amazon benzeri çoklu kategori desteği
 * Bir ürün birden fazla kategoride yer alabilir
 */
@Entity
@Table(
        name = "product_categories",
        indexes = {
                @Index(name = "idx_pc_product_id", columnList = "product_id"),
                @Index(name = "idx_pc_category_id", columnList = "category_id"),
                @Index(name = "idx_pc_is_primary", columnList = "is_primary"),
                @Index(name = "idx_pc_company_code", columnList = "company_code"),
                @Index(name = "idx_pc_display_order", columnList = "display_order")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_product_category",
                        columnNames = {"product_id", "category_id", "company_code"}
                )
        }
)
@Comment("Ürün-Kategori İlişki Tablosu - Çoklu kategori desteği")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategory extends TOpenSimpleCompanyEntity {

    @Column(name = "product_id", nullable = false, length = 36)
    @Comment("Ürün ID")
    private String productId;

    @Column(name = "category_id", nullable = false, length = 36)
    @Comment("Kategori ID")
    private String categoryId;

    @Column(name = "is_primary", nullable = false)
    @Comment("Ana Kategori mi? - Ürün için birincil kategori")
    @Builder.Default
    private Boolean isPrimary = false;

    @Column(name = "display_order")
    @Comment("Görüntüleme Sırası - Kategoride ürünün sırası")
    @Builder.Default
    private Integer displayOrder = 0;

    @Column(name = "is_featured", nullable = false)
    @Comment("Öne Çıkan Ürün mü? - Kategoride öne çıkarılsın mı")
    @Builder.Default
    private Boolean isFeatured = false;

    @Column(name = "custom_name", length = 500)
    @Comment("Özel Ürün Adı - Bu kategoride farklı isimle göster")
    private String customName;

    @Column(name = "custom_description", columnDefinition = "TEXT")
    @Comment("Özel Açıklama - Bu kategoriye özel açıklama")
    private String customDescription;

    @Column(name = "is_active", nullable = false)
    @Comment("Aktif mi? - Bu kategoride gösterilsin mi")
    @Builder.Default
    private Boolean isActive = true;
}
