package com.sedcore.entity;

import jakarta.persistence.*;
import lombok.*;

import com.sedcore.enums.AttributeType;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.ArrayList;
import java.util.List;

/**
 * CategoryVariant Entity - Kategori varyantlarını temsil eden sınıf.
 * Bu sınıf, PostgreSQL veritabanında 'category_variants' tablosuna karşılık gelir.
 */
@Entity
@Table(name = "category_variants")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryVariant extends TOpenSimpleDbEntity {

    @ManyToOne // Her bir varyant bir kategoriye aittir
    @JoinColumn(name = "category_id", nullable = false) // Dış anahtar
    private Category category; // İlişkili kategori

    @Column(name = "variant_key", nullable = false, length = 100)
    private String variantKey; // Varyant anahtarı, örneğin: size, color

    @Column(name = "variant_name", nullable = false, length = 200)
    private String variantName; // Varyant adı, görünen isim

    @Column(name = "variant_name_en", length = 200)
    private String variantNameEn; // Varyant adı (İngilizce)

    @Enumerated(EnumType.STRING)
    @Column(name = "variant_type", nullable = false, length = 30)
    private AttributeType variantType; // Varyant tipi (SELECT, COLOR, TEXT vb.)

    @Builder.Default
    @Column(name = "is_required", nullable = false)
    private Boolean isRequired = false; // Zorunlu mu?
    
    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true; // aktif mi?

    @Builder.Default
    @Column(name = "display_order")
    private Integer displayOrder = 0; // Görüntüleme sırası

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "options", columnDefinition = "jsonb")
    @Builder.Default
    private List<String> options = new ArrayList<>(); // Varyant seçenekleri

    // Diğer alanlar...
}