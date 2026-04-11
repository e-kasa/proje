package com.sedcore.customer.model;

import com.sedcore.common.enums.PaymentType;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CustomerPaymentDto {
    private BigDecimal amount;
    private PaymentType paymentType;   // default: CASH
    private String description;
    private String referenceNumber;    // dekont/çek no
    private String bankName;
}
