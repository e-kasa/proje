package com.sedcore.catalog.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

/**
 * Firma-Kategori İlişki Tablosu
 *
 * Global kategori havuzundan her firma kendi kategorilerini seçer.
 * Örnek: "berkspt" firması sadece Giyim kategorilerini seçer.
 * Flutter/React uygulamaları /my-categories endpoint'ini çağırdığında
 * sadece firmanın seçtiği kategoriler döner.
 *
 * company_code alanı TOpenSimpleCompanyEntity'den miras alındığı için
 * Hibernate @Filter otomatik devreye girer: WHERE company_code IN (:cpCode)
 */
@Entity
@Table(
        name = "company_categories",
        indexes = {
                @Index(name = "idx_cc_company_code",  columnList = "company_code"),
                @Index(name = "idx_cc_category_id",   columnList = "category_id"),
                @Index(name = "idx_cc_is_active",     columnList = "is_active")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_company_category",
                        columnNames = {"company_code", "category_id"}
                )
        }
)
@Comment("Firma-Kategori İlişki Tablosu - Her firma global havuzdan kategori seçer")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompanyCategory extends TOpenSimpleCompanyEntity {

    @Column(name = "category_id", nullable = false, length = 36)
    @Comment("Seçilen Kategori ID - Global kategori havuzundaki kategori")
    private String categoryId;

    @Column(name = "is_active", nullable = false)
    @Comment("Aktif mi?")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "display_order")
    @Comment("Firmaya özel görüntüleme sırası")
    @Builder.Default
    private Integer displayOrder = 0;

    // Kategori detaylarına kolay erişim için - DB'de saklanmaz
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", insertable = false, updatable = false)
    private Category category;
}
