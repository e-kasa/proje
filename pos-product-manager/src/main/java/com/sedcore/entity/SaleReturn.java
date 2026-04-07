package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * SaleReturn Entity — Satış iadesi ana kaydı.
 *
 * Her iade işlemi için benzersiz bir iade numarası üretilir (RET-yyyyMMdd-XXXXXX).
 * İade edilen kalemler {@link SaleReturnItem} üzerinden takip edilir.
 * Stok hareketi: {@link com.sedcore.enums.StockMovementType#SALE_RETURN_IN}
 */
@Entity
@Table(name = "sale_returns", indexes = {
    @Index(name = "idx_sr_sale",   columnList = "sale_id"),
    @Index(name = "idx_sr_number", columnList = "return_number")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleReturn extends TOpenSimpleCompanyEntity {

    // ===== ANA BİLGİLER =====

    @Column(name = "return_number", unique = true, nullable = false, length = 50)
    private String returnNumber;  // RET-20240407-AB12CD

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id", nullable = false)
    private Sale sale;

    // ===== İADE TUTARI =====

    @Column(name = "total_return_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal totalReturnAmount;

    // ===== İADE NEDENİ =====

    @Column(name = "reason", length = 50)
    private String reason;        // damaged, wrong_product, customer_return ...

    @Column(name = "reason_label", length = 100)
    private String reasonLabel;   // "Hasarlı Ürün" ...

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ===== TARİH =====

    @Column(name = "return_date", nullable = false)
    private LocalDateTime returnDate;

    // ===== KALEMLER =====

    @OneToMany(mappedBy = "saleReturn", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SaleReturnItem> items;
}
