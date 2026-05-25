package com.sedcore.company.entity;

import java.math.BigDecimal;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "company_settings")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class CompanySetting extends TOpenSimpleCompanyEntity {

    @Column(name = "company_name", length = 200)
    private String companyName;

    @Column(name = "tax_number", length = 50)
    private String taxNumber;

    @Column(name = "tax_office", length = 100)
    private String taxOffice;

    @Column(name = "phone", length = 30)
    private String phone;

    @Column(name = "email", length = 200)
    private String email;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "country", length = 100)
    @Builder.Default
    private String country = "Türkiye";

    @Column(name = "website", length = 200)
    private String website;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Column(name = "currency", length = 10)
    @Builder.Default
    private String currency = "TRY";

    @Column(name = "sector_type", length = 50)
    private String sectorType;

    // ===== VERGİ DEFAULT'LARI (Sprint 2026-05-25) =====
    // Ürün/varyantta override yoksa kaskad: SaleItemRequest → VariantPricing → CompanySetting.

    /** Sektörün varsayılan KDV oranı (%). AUTO_PARTS=20, FOOTWEAR=10 önerisi. */
    @Column(name = "default_vat_rate", precision = 5, scale = 2)
    private BigDecimal defaultVatRate;

    /** Sektörün varsayılan ÖTV oranı (%). FOOTWEAR=0, AUTO_PARTS ürüne göre değişir (default 0). */
    @Column(name = "default_otv_rate", precision = 5, scale = 2)
    private BigDecimal defaultOtvRate;

    /**
     * Bu sektörde ÖTV aktif mi? UI'da ÖTV alanlarının görünürlüğünü branşlandırır.
     * AUTO_PARTS → true; FOOTWEAR, GENERAL → false. Boolean false default columnDefinition ile garanti.
     */
    @Column(name = "otv_enabled", nullable = false, columnDefinition = "boolean DEFAULT false")
    @Builder.Default
    private Boolean otvEnabled = false;
}
