package com.sedcore.entity;

import com.sedcore.enums.CustomerType;
import com.sedcore.enums.RiskStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Customer Entity - Müşteri bilgileri ve cari hesap temel bilgileri
 */
@Entity
@Table(name = "supplier")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Supplier extends TOpenSimpleCompanyEntity {

    // ===== TEMEL BİLGİLER =====

    @Column(length = 200, nullable = false)
    private String name;

    @Column(name = "contact_name", length = 200)
    private String contactName; // İletişim kişisi

    @Column(length = 20)
    private String phone;

    @Column(length = 200)
    private String email;

    @Column(length = 500)
    private String address;

    @Column(length = 500)
    private String notes;

    @Column(length = 500)
    private String website; // Tedarikçinin ürün kataloğu / sipariş sitesi

    // ===== CARİ HESAP BİLGİLERİ =====

    @Enumerated(EnumType.STRING)
    @Column(name = "customer_type", length = 20)
    @Builder.Default
    private CustomerType customerType = CustomerType.INDIVIDUAL;

    @Column(name = "tax_number", length = 50)
    private String taxNumber; // Vergi numarası (kurumsal için)

    @Column(name = "tax_office", length = 100)
    private String taxOffice; // Vergi dairesi

    @Column(name = "credit_limit", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal creditLimit = BigDecimal.ZERO; // Kredi limiti

    @Column(name = "payment_term_days")
    @Builder.Default
    private Integer paymentTermDays = 30; // Ödeme vadesi (gün)

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_status", length = 20)
    @Builder.Default
    private RiskStatus riskStatus = RiskStatus.NORMAL; // Risk durumu

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true; // Aktif mi?

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false; // Soft delete

    // ===== İLİŞKİLER =====

    @OneToOne(mappedBy = "supplier", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private SupplierAccount account; // Cari hesap özeti
}
