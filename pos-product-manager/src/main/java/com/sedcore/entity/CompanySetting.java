package com.sedcore.entity;

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
}
