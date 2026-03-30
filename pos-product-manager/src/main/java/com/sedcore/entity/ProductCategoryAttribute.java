package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.ArrayList;
import java.util.List;

/**
 * Ürün-Kategori Özellik Değerleri
 * Bir ürünün belirli kategorideki özel özelliklerinin değerleri
 * Örnek: iPhone 15 -> Elektronik kategorisinde -> Marka: Apple, Ekran: 6.1 inç
 */
@Entity
@Table(
        name = "product_category_attributes",
        indexes = {
                @Index(name = "idx_pca_product_id", columnList = "product_id"),
                @Index(name = "idx_pca_category_id", columnList = "category_id"),
                @Index(name = "idx_pca_attribute_id", columnList = "category_attribute_id"),
                @Index(name = "idx_pca_company_code", columnList = "company_code"),
                @Index(name = "idx_pca_attribute_key", columnList = "attribute_key")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_product_category_attribute",
                        columnNames = {"product_id", "category_id", "category_attribute_id", "company_code"}
                )
        }
)
@Comment("Ürün-Kategori Özellik Değerleri")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategoryAttribute extends TOpenSimpleCompanyEntity {

    @Column(name = "product_id", nullable = false, length = 36)
    @Comment("Ürün ID")
    private String productId;

    @Column(name = "category_id", nullable = false, length = 36)
    @Comment("Kategori ID")
    private String categoryId;

    @Column(name = "category_attribute_id", nullable = false, length = 36)
    @Comment("Kategori Özellik Tanımı ID")
    private String categoryAttributeId;

    @Column(name = "attribute_key", nullable = false, length = 100)
    @Comment("Özellik Anahtarı - Hızlı erişim için")
    private String attributeKey;

    @Column(name = "attribute_name", length = 200)
    @Comment("Özellik Adı - Cache için")
    private String attributeName;

    @Column(name = "value_text", columnDefinition = "TEXT")
    @Comment("Metin Değeri - TEXT tipindeki değerler için")
    private String valueText;

    @Column(name = "value_number")
    @Comment("Sayısal Değer - NUMBER tipindeki değerler için")
    private Double valueNumber;

    @Column(name = "value_boolean")
    @Comment("Boolean Değer - BOOLEAN tipindeki değerler için")
    private Boolean valueBoolean;

    @Column(name = "value_date")
    @Comment("Tarih Değeri - DATE tipindeki değerler için")
    private java.time.LocalDate valueDate;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "value_select", columnDefinition = "jsonb")
    @Comment("Seçim Değerleri - SELECT/MULTI_SELECT için")
    @Builder.Default
    private List<String> valueSelect = new ArrayList<>();

    @Column(name = "value_min")
    @Comment("Minimum Değer - RANGE tipi için")
    private Double valueMin;

    @Column(name = "value_max")
    @Comment("Maximum Değer - RANGE tipi için")
    private Double valueMax;

    @Column(name = "unit", length = 50)
    @Comment("Birim - Örn: kg, cm, GB")
    private String unit;

    @Column(name = "display_value", length = 500)
    @Comment("Görüntülenecek Değer - UI için formatlanmış")
    private String displayValue;

    @Column(name = "is_verified", nullable = false)
    @Comment("Doğrulanmış mı? - Admin onayı")
    @Builder.Default
    private Boolean isVerified = false;

    @Column(name = "sort_order")
    @Comment("Sıralama - Gösterim sırası")
    @Builder.Default
    private Integer sortOrder = 0;
}
