package com.sedcore.customer.entity;

import com.sedcore.common.enums.CustomerType;
import com.sedcore.common.enums.RiskStatus;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "customer", indexes = {
    @Index(name = "idx_customer_phone", columnList = "phone"),
    @Index(name = "idx_customer_tax", columnList = "tax_number")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Customer extends TOpenSimpleCompanyEntity {

    @Column(length = 200, nullable = false)
    private String name;

    @Column(length = 20)
    private String phone;

    @Column(length = 200)
    private String email;

    @Column(length = 500)
    private String address;

    @Column(length = 500)
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(name = "customer_type", length = 20)
    @Builder.Default
    private CustomerType customerType = CustomerType.INDIVIDUAL;

    @Column(name = "tax_number", length = 50)
    private String taxNumber;

    @Column(name = "tax_office", length = 100)
    private String taxOffice;

    @Column(name = "bank_name", length = 100)
    private String bankName;

    @Column(name = "credit_limit", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal creditLimit = BigDecimal.ZERO;

    @Column(name = "payment_term_days")
    @Builder.Default
    private Integer paymentTermDays = 30;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_status", length = 20)
    @Builder.Default
    private RiskStatus riskStatus = RiskStatus.NORMAL;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;

    @OneToOne(mappedBy = "customer", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private CustomerAccount account;
}
