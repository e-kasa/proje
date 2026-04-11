package com.sedcore.inventory.entity;

import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Comment;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(
        name = "sites",
        indexes = {
                @Index(name = "idx_site_company_code", columnList = "company_code"),
                @Index(name = "idx_site_code", columnList = "site_code"),
                @Index(name = "idx_site_domain", columnList = "domain"),
                @Index(name = "idx_site_status", columnList = "status"),
                @Index(name = "idx_site_is_deleted", columnList = "is_deleted")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_site_code_company",
                        columnNames = {"site_code", "company_code"}
                ),
                @UniqueConstraint(
                        name = "uk_site_domain",
                        columnNames = {"domain"}
                )
        }
)
@Comment("E-Ticaret Site Tablosu")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Site extends TOpenSimpleCompanyEntity {

    @Column(name = "site_code", nullable = false, length = 50)
    @Comment("Site Kodu")
    private String siteCode;

    @Column(name = "name", nullable = false, length = 200)
    @Comment("Site Adı")
    private String name;

    @Column(name = "domain", nullable = false, length = 200)
    @Comment("Domain - www.a.com")
    private String domain;

    @Column(name = "description", columnDefinition = "TEXT")
    @Comment("Açıklama")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Comment("Durum")
    @Builder.Default
    private ProductStatus status = ProductStatus.ACTIVE;

    @Column(name = "logo_url", length = 500)
    @Comment("Logo URL")
    private String logoUrl;

    @Column(name = "favicon_url", length = 500)
    @Comment("Favicon URL")
    private String faviconUrl;

    @Column(name = "default_language", length = 5)
    @Comment("Varsayılan Dil")
    @Builder.Default
    private String defaultLanguage = "tr";

    @Column(name = "default_currency", length = 3)
    @Comment("Varsayılan Para Birimi")
    @Builder.Default
    private String defaultCurrency = "TRY";

    @Column(name = "theme", length = 100)
    @Comment("Tema")
    private String theme;

    @Column(name = "is_deleted")
    @Comment("Silinmiş mi?")
    @Builder.Default
    private Boolean isDeleted = false;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "configuration", columnDefinition = "jsonb")
    @Comment("Site Ayarları - JSON")
    @Builder.Default
    private Map<String, Object> configuration = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "contact_info", columnDefinition = "jsonb")
    @Comment("İletişim Bilgileri - JSON")
    @Builder.Default
    private Map<String, Object> contactInfo = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "seo_settings", columnDefinition = "jsonb")
    @Comment("SEO Ayarları - JSON")
    @Builder.Default
    private Map<String, Object> seoSettings = new HashMap<>();
}