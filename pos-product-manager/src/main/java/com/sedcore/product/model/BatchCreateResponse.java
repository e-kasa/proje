package com.sedcore.product.model;

import com.sedcore.purchase.model.SupplierClaimSummary;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Toplu ürün giriş sonucu.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchCreateResponse {

    /** Oluşturulan Purchase kaydının ID'si */
    private String purchaseId;

    /** Fatura numarası */
    private String invoiceNumber;

    /** Başarılı kalem sayısı */
    private int successCount;

    /** Başarısız kalem sayısı */
    private int failCount;

    /** Toplam fatura tutarı */
    private BigDecimal totalAmount;

    /** Kalem bazlı sonuçlar — tempId ile Flutter'a eşlenir */
    private List<BatchItemResult> results;

    /** Eksik teslimat nedeniyle açılan SupplierClaim özeti (null → claim açılmadı). */
    private SupplierClaimSummary claim;
}
