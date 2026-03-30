package com.sedcore.model;

import java.math.BigDecimal;

import com.sedcore.enums.CustomerType;
import com.sedcore.enums.RiskStatus;

import lombok.Data;

@Data
public class SupplierDto {
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
}
