package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "revenues", indexes = {
    @Index(name = "idx_revenue_date", columnList = "revenue_date")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Revenue extends TOpenSimpleCompanyEntity {

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "revenue_date", nullable = false)
    private LocalDateTime revenueDate;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod;

    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    @Builder.Default
    @Column(name = "is_deleted")
    private Boolean isDeleted = false;
}
