package com.sedcore.finance.model;

import com.sedcore.common.enums.TransactionType;
import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AccountTransactionResponse extends DtoBaseModel {
    private String id;

    // İlişkili taraf
    private String supplierId;
    private String supplierName;
    private String customerId;
    private String customerName;

    // Hareket bilgileri
    private TransactionType transactionType;
    private String transactionTypeLabel;
    private BigDecimal debitAmount;
    private BigDecimal creditAmount;
    private BigDecimal balance;
    private String description;
    private String notes;

    // Referans
    private String referenceId;
    private String referenceNumber;
    private String referenceType;

    // Tarihler
    private LocalDateTime transactionDate;
    private LocalDate dueDate;

    // Durum
    private Boolean isOverdue;
    private Boolean isCancelled;
    private LocalDateTime cancelledDate;
    private String cancelledBy;
}
