package com.sedcore.catalog.entity;


import jakarta.persistence.*;
import lombok.*;

import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Category Entity - Kategorileri temsil eden sınıf.
 * Bu sınıf, PostgreSQL veritabanında 'categories' tablosuna karşılık gelmektedir.
 */
@Entity
@Table(name = "categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category extends TOpenSimpleDbEntity {

    @Column(name = "name", nullable = false, length = 200)
    private String name; // Kategori adı, örneğin: Spor Ayakkabı

    @Column(name = "slug", nullable = false, length = 200, unique = true)
    private String slug; // URL dostu isim, örneğin: spor-ayakkabi

    @Column(name = "description", columnDefinition = "TEXT")
    private String description; // Kategori açıklaması

    @Column(name = "image_url", length = 500)
    private String imageUrl; // Kategoriye ait görsel URL

    @Column(name = "icon", length = 100)
    private String icon; // Kategori simgesi

    @Builder.Default
    @Column(name = "sort_order")
    private Integer sortOrder = 0; // Kategorinin sıralama numarası

    @Builder.Default
    @Column(name = "level")
    private Integer level = 0; // Kategori seviyesi (0=Ana, 1=Alt, 2=Alt-Alt)

    @Column(name = "path", length = 500)
    private String path; // Kategori yolu, örneğin: /ayakkabi/spor-ayakkabi

    @Builder.Default
    @Column(name = "is_deleted")
    private Boolean isSoftDeleted = false; // Kategori silinmiş mi? Soft delete

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ProductStatus status = ProductStatus.ACTIVE; // Kategori durumu (DRAFT, ACTIVE, INACTIVE, ARCHIVED)

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>(); // Esnek özellikler için JSON

    @Column(name = "meta_title", length = 200)
    private String metaTitle; // SEO başlığı

    @Column(name = "meta_description", length = 500)
    private String metaDescription; // SEO açıklaması

    @Column(name = "meta_keywords", length = 500)
    private String metaKeywords; // SEO anahtar kelimeleri

    // ===== İlişkisel Alanlar =====

    @ManyToOne
    @JoinColumn(name = "parent_id") // Alt kategorilerin üst kategori referansı
    private Category parentCategory; // Üst kategori

    @OneToMany(mappedBy = "parentCategory", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Category> children; // Alt Kategoriler

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CategoryVariant> variants; // Kategori Varyantları

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CategoryAttribute> attributes; // Kategori Özellikleri

    @Transient
    private Integer childrenCount; // Alt kategori sayısı

    @Transient
    private Integer variantCount; // Varyant sayısı

    @Transient
    private Integer attributeCount; // Özellik sayısı

    @Transient
    private Long productCount; // Bu kategorideki ürün sayısı
}