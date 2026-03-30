package com.sedcore.entity;

import com.sedcore.enums.MediaType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

@Entity
@Table(
        name = "product_media",
        indexes = {
                @Index(name = "idx_media_company_code", columnList = "company_code"),
                @Index(name = "idx_media_product_id", columnList = "product_id"),
                @Index(name = "idx_media_variant_id", columnList = "variant_id"),
                @Index(name = "idx_media_type", columnList = "media_type"),
                @Index(name = "idx_media_sort_order", columnList = "sort_order"),
                @Index(name = "idx_media_is_deleted", columnList = "is_deleted")
        }
)
@Comment("Ürün Medya Tablosu")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductMedia extends TOpenSimpleCompanyEntity {

    @Column(name = "product_id", nullable = false, length = 36)
    @Comment("Ürün ID")
    private String productId;

    @Column(name = "variant_id", length = 36)
    @Comment("Varyant ID - null ise tüm varyantlar")
    private String variantId;

    @Enumerated(EnumType.STRING)
    @Column(name = "media_type", nullable = false, length = 20)
    @Comment("Medya Tipi - IMAGE, VIDEO, DOCUMENT")
    private MediaType mediaType;

    @Column(name = "url", nullable = false, length = 1000)
    @Comment("Medya URL")
    private String url;

    @Column(name = "thumbnail_url", length = 1000)
    @Comment("Thumbnail URL")
    private String thumbnailUrl;

    @Column(name = "title", length = 500)
    @Comment("Başlık")
    private String title;

    @Column(name = "alt_text", length = 500)
    @Comment("Alt Text - SEO")
    private String altText;

    @Column(name = "is_primary")
    @Comment("Ana Medya mı?")
    @Builder.Default
    private Boolean isPrimary = false;

    @Column(name = "sort_order")
    @Comment("Sıralama")
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(name = "file_size")
    @Comment("Dosya Boyutu (byte)")
    private Long fileSize;

    @Column(name = "mime_type", length = 100)
    @Comment("MIME Type")
    private String mimeType;

    @Column(name = "width")
    @Comment("Genişlik (piksel)")
    private Integer width;

    @Column(name = "height")
    @Comment("Yükseklik (piksel)")
    private Integer height;

    @Column(name = "duration")
    @Comment("Süre (saniye) - video için")
    private Integer duration;

    @Column(name = "is_deleted")
    @Comment("Silinmiş mi?")
    @Builder.Default
    private Boolean isDeleted = false;
}