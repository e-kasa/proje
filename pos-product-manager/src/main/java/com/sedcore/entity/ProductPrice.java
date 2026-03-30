package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;

import java.math.BigDecimal;
import java.util.Date;

@Entity
@Table(
        name = "product_prices",
        indexes = {
                @Index(name = "idx_price_company_code", columnList = "company_code"),
                @Index(name = "idx_price_site_id", columnList = "site_id"),
                @Index(name = "idx_price_product_id", columnList = "product_id"),
                @Index(name = "idx_price_variant_id", columnList = "variant_id"),
                @Index(name = "idx_price_is_active", columnList = "is_active"),
                @Index(name = "idx_price_dates", columnList = "start_date, end_date")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_price_site_variant",
                        columnNames = {"site_id", "product_id", "variant_id", "company_code"}
                )
        }
)
@Comment("Ürün Fiyat Tablosu - Site bazlı")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductPrice extends TOpenSimpleCompanyEntity {

    @Column(name = "site_id", nullable = false, length = 36)
    @Comment("Site ID")
    private String siteId;

    @Column(name = "product_id", nullable = false, length = 36)
    @Comment("Ürün ID")
    private String productId;

    @Column(name = "variant_id", length = 36)
    @Comment("Varyant ID - null ise tüm varyantlar")
    private String variantId;

    @Column(name = "price", nullable = false, precision = 15, scale = 2)
    @Comment("Satış Fiyatı")
    private BigDecimal price;

    @Column(name = "list_price", precision = 15, scale = 2)
    @Comment("Liste Fiyatı - Çizili fiyat")
    private BigDecimal listPrice;

    @Column(name = "cost_price", precision = 15, scale = 2)
    @Comment("Maliyet Fiyatı")
    private BigDecimal costPrice;

    @Column(name = "currency", length = 3, nullable = false)
    @Comment("Para Birimi")
    @Builder.Default
    private String currency = "TRY";

    @Column(name = "discount_amount", precision = 15, scale = 2)
    @Comment("İndirim Miktarı")
    private BigDecimal discountAmount;

    @Column(name = "discount_percentage", precision = 5, scale = 2)
    @Comment("İndirim Oranı (%)")
    private BigDecimal discountPercentage;

    @Column(name = "is_active", nullable = false)
    @Comment("Aktif mi?")
    @Builder.Default
    private Boolean isActive = true;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "start_date")
    @Comment("Başlangıç Tarihi")
    private Date startDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "end_date")
    @Comment("Bitiş Tarihi")
    private Date endDate;

    @Column(name = "min_order_quantity")
    @Comment("Minimum Sipariş Adedi")
    @Builder.Default
    private Integer minOrderQuantity = 1;

    @Column(name = "max_order_quantity")
    @Comment("Maksimum Sipariş Adedi")
    private Integer maxOrderQuantity;

    @Column(name = "campaign_name", length = 200)
    @Comment("Kampanya Adı")
    private String campaignName;

    @Column(name = "notes", length = 1000)
    @Comment("Notlar")
    private String notes;
}