package com.sedcore.model.reports;

import com.sedcore.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AccountStatementEntry {
    private BigDecimal openingBalance;
    private BigDecimal closingBalance;
    private BigDecimal totalDebit;
    private BigDecimal totalCredit;
    private List<TransactionLine> transactions;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TransactionLine {
        private String id;
        private LocalDateTime transactionDate;
        private TransactionType transactionType;
        private String description;
        private String referenceNumber;
        private BigDecimal debitAmount;
        private BigDecimal creditAmount;
        private BigDecimal runningBalance;
    }
}
