package com.sedcore.finance.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ExpenseRequest {

    @NotBlank
    private String title;

    private String description;

    @NotNull
    @Positive
    private BigDecimal amount;

    private String category;

    @NotNull
    private LocalDateTime expenseDate;

    private String paymentMethod;

    private String referenceNumber;

    private String status;
}
