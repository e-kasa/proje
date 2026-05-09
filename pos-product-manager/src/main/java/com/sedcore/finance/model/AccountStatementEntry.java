package com.sedcore.finance.model;

import com.sedcore.common.enums.TransactionType;
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
    /**
     * Sprint 8 hot-fix (Bug B): Denormalize {@code CustomerAccount.currentBalance}
     * (veya {@code SupplierAccount.currentBalance}). closingBalance transaction'lardan
     * hesaplanır; currentBalance write-through cache değer. Drift varsa farklı olabilir
     * → frontend bu değeri primer bakiye olarak gösterir.
     */
    private BigDecimal currentBalance;
    private BigDecimal totalDebit;
    private BigDecimal totalCredit;
    /** Customer.creditLimit veya Supplier.creditLimit. Null ise frontend gizler. */
    private BigDecimal creditLimit;
    /** CustomerAccount/SupplierAccount.availableCreditLimit (creditLimit - currentBalance). */
    private BigDecimal availableCreditLimit;
    /** Limit aşıldı mı (availableCreditLimit < 0). */
    private Boolean isCreditLimitExceeded;
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
        /**
         * Sprint 11d — bağlı satışın plaka snapshot'ı (Sale.vehiclePlateSnapshot).
         * Sale FK yoksa veya plaka atanmamışsa null. Frontend ekstre kartında chip
         * + plaka filtresi olarak kullanır.
         */
        private String vehiclePlate;
    }
}
