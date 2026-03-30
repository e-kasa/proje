package com.sedcore.entity;

import com.sedcore.enums.ProductStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

import java.util.Date;

@Entity
@Table(
        name = "site_products",
        indexes = {
                @Index(name = "idx_site_product_company_code", columnList = "company_code"),
                @Index(name = "idx_site_product_site_id", columnList = "site_id"),
                @Index(name = "idx_site_product_product_id", columnList = "product_id"),
                @Index(name = "idx_site_product_status", columnList = "status"),
                @Index(name = "idx_site_product_is_published", columnList = "is_published"),
                @Index(name = "idx_site_product_is_featured", columnList = "is_featured"),
                @Index(name = "idx_site_product_is_deleted", columnList = "is_deleted")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_site_product_unique",
                        columnNames = {"site_id", "product_id", "company_code"}
                )
        }
)
@Comment("Ürün-Site Eşleştirme")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SiteProduct extends TOpenSimpleCompanyEntity {

    @Column(name = "site_id", nullable = false, length = 36)
    @Comment("Site ID")
    private String siteId;

    @Column(name = "product_id", nullable = false, length = 36)
    @Comment("Ürün ID")
    private String productId;

    @Column(name = "is_published", nullable = false)
    @Comment("Yayında mı?")
    @Builder.Default
    private Boolean isPublished = false;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "published_at")
    @Comment("Yayın Tarihi")
    private Date publishedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Comment("Durum")
    @Builder.Default
    private ProductStatus status = ProductStatus.DRAFT;

    @Column(name = "is_featured")
    @Comment("Öne Çıkan mı?")
    @Builder.Default
    private Boolean isFeatured = false;

    @Column(name = "sort_order")
    @Comment("Sıralama")
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(name = "view_count")
    @Comment("Görüntülenme Sayısı")
    @Builder.Default
    private Long viewCount = 0L;

    @Column(name = "sales_count")
    @Comment("Satış Sayısı")
    @Builder.Default
    private Long salesCount = 0L;

    @Column(name = "custom_title", length = 500)
    @Comment("Özel Başlık")
    private String customTitle;

    @Column(name = "custom_description", columnDefinition = "TEXT")
    @Comment("Özel Açıklama")
    private String customDescription;

    @Column(name = "is_deleted")
    @Comment("Silinmiş mi?")
    @Builder.Default
    private Boolean isDeleted = false;
}