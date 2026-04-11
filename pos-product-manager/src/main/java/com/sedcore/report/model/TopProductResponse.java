package com.sedcore.report.model;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

/** En çok satan ürün satırı */
@Data
@Builder
public class TopProductResponse {
    private String productId;
    private String productName;
    private String category;
    private String imageUrl;
    private Long   unitsSold;
    private BigDecimal revenue;
    private Double revenueShare;   // toplam içindeki yüzde
    private Integer stockQuantity;
    private String trend;          // "up" | "down" | "stable"
}
