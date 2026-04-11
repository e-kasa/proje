package com.sedcore.supplier.model;

import com.sedcore.common.enums.PaymentType;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class SupplierPaymentDto {
    private BigDecimal amount;
    private PaymentType paymentType;   // default: CASH
    private String description;
    private String referenceNumber;    // dekont/çek no
}
