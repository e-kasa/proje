package com.sedcore.entity;

import jakarta.persistence.*;
import lombok.*;
import com.sedcore.enums.AttributeType;
import com.towpen.base.db.model.TOpenSimpleDbEntity;

import java.util.ArrayList;
import java.util.List;

/**
 * CategoryAttribute Entity - Kategori özelliklerini temsil eden sınıf.
 * Bu sınıf, PostgreSQL veritabanında 'category_attributes' tablosuna karşılık gelir.
 */
@Entity
@Table(name = "category_attributes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryAttribute extends TOpenSimpleDbEntity {

    @ManyToOne // Her bir özellik bir kategoriye aittir
    @JoinColumn(name = "category_id", nullable = false) // Dış anahtar
    private Category category; // İlişkili kategori

    @Column(name = "attribute_key", nullable = false, length = 100)
    private String attributeKey; // Özellik anahtarı, örneğin: brand, screen_size

    @Column(name = "attribute_name", nullable = false, length = 200)
    private String attributeName; // Özellik adı, görünen isim

    @Column(name = "attribute_name_en", length = 200)
    private String attributeNameEn; // Özellik adı (İngilizce)

    @Enumerated(EnumType.STRING)
    @Column(name = "attribute_type", nullable = false, length = 30)
    private AttributeType attributeType; // Özellik tipi (TEXT, NUMBER, SELECT vb.)

    @Builder.Default
    @Column(name = "is_required", nullable = false)
    private Boolean isRequired = false; // Zorunlu mu?

    @Builder.Default
    @Column(name = "is_filterable", nullable = false)
    private Boolean isFilterable = true; // Filtrelenebilir mi?

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true; // Aktif mi?

    // Diğer alanlar...
}
