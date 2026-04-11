package com.sedcore.model.finance;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Date;

@Data
@Builder
public class RevenueResponse {
    private String id;
    private String title;
    private String description;
    private BigDecimal amount;
    private String category;
    private LocalDateTime revenueDate;
    private String paymentMethod;
    private String referenceNumber;
    private Date createTime;
}
