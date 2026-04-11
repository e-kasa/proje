package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "expenses", indexes = {
    @Index(name = "idx_expense_date", columnList = "expense_date"),
    @Index(name = "idx_expense_category", columnList = "category")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Expense extends TOpenSimpleCompanyEntity {

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "expense_date", nullable = false)
    private LocalDateTime expenseDate;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod;  // CASH, BANK_TRANSFER, CREDIT_CARD

    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "PAID";  // PAID, PENDING, CANCELLED

    @Builder.Default
    @Column(name = "is_deleted")
    private Boolean isDeleted = false;
}
