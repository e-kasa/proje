package com.sedcore.customer.model;

import com.sedcore.common.enums.CustomerType;
import com.sedcore.common.enums.RiskStatus;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CustomerDto {
    @NotBlank(message = "Müşteri adı zorunludur")
    private String name;
    private String phone;
    private String email;
    private String address;
    private String notes;
    private CustomerType customerType = CustomerType.INDIVIDUAL;
    private String taxNumber;
    private String taxOffice;
    private BigDecimal creditLimit = BigDecimal.ZERO;
    private Integer paymentTermDays = 30;
    private RiskStatus riskStatus = RiskStatus.NORMAL;
    private Boolean isActive = true;
}
