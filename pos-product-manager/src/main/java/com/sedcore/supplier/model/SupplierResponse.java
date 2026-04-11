package com.sedcore.supplier.model;

import com.sedcore.common.enums.CustomerType;
import com.sedcore.common.enums.RiskStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Tedarikçi / Müşteri Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierResponse {

    private String id;
    private String name;
    private String contactName;
    private String phone;
    private String email;
    private String address;
    private String notes;

    private CustomerType customerType;
    private String taxNumber;
    private String taxOffice;

    private BigDecimal creditLimit;
    private Integer paymentTermDays;
    private RiskStatus riskStatus;

    private Boolean isActive;
    private Boolean isDeleted;

    // Cari hesap özeti
    private BigDecimal balance;        // Bakiye (SupplierAccount'tan)
    private BigDecimal totalDebt;
    private BigDecimal totalPaid;
}
