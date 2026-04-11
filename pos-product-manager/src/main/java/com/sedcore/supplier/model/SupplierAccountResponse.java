package com.sedcore.supplier.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierAccountResponse {
    private String id;
    private String supplierId;
    private String supplierName;
    private BigDecimal creditLimit;
    private BigDecimal currentBalance;
    private BigDecimal totalDebt;
    private BigDecimal totalCredit;
    private BigDecimal overdueAmount;
    private BigDecimal availableCreditLimit;
    private Boolean isCreditLimitExceeded;
    private Long totalTransactionCount;
    private LocalDateTime lastTransactionDate;
    private LocalDateTime lastPaymentDate;
    private LocalDateTime lastPurchaseDate;
}
