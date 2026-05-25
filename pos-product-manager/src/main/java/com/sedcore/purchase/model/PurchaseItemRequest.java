package com.sedcore.purchase.model;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PurchaseItemRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    /**
     * Fatura üzerindeki miktar — gerçek teslimatla aynı olmayabilir.
     * null gelirse {@code quantity} değeri kullanılır (backward compat).
     */
    private Integer invoiceQuantity;

    /**
     * Depoya/mağazaya giren fiziksel miktar.
     * null gelirse {@code invoiceQuantity} kadar geldi varsayılır.
     */
    private Integer receivedQuantity;

    /**
     * Geriye dönük uyumluluk alanı. invoiceQuantity null ise bu değer
     * hem fatura hem de teslim miktarı olarak kullanılır.
     */
    @NotNull(message = "Miktar zorunludur")
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;

    @NotNull(message = "Birim fiyat zorunludur")
    @Positive(message = "Birim fiyat pozitif olmalıdır")
    private BigDecimal unitPrice;

    @DecimalMin(value = "0.00", message = "KDV oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "KDV oranı 100'den büyük olamaz")
    private BigDecimal taxRate;

    /** İskonto oranı (%) — Sprint 2026-05-25. Kalem bazlı; null = 0. */
    @DecimalMin(value = "0.00", message = "İskonto oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "İskonto oranı 100'den büyük olamaz")
    private BigDecimal discountRate;

    /** ÖTV oranı (%) — Sprint 2026-05-25. AUTO_PARTS'ta dolu; FOOTWEAR'da null/0. */
    @DecimalMin(value = "0.00", message = "ÖTV oranı 0'dan küçük olamaz")
    @DecimalMax(value = "100.00", message = "ÖTV oranı 100'den büyük olamaz")
    private BigDecimal otvRate;

    /**
     * true ise {@code unitPrice} KDV+ÖTV dahil etiket fiyatıdır;
     * backend PricingCalculator ile tersine ayrıştırır. Null/false → KDV hariç.
     */
    private Boolean vatIncluded;

    private String notes;

    // ── Hesaplama yardımcıları ────────────────────────────────────────────────

    /** Fatura miktarını döner; invoiceQuantity null ise quantity kullanılır. */
    public int resolvedInvoiceQty() {
        return invoiceQuantity != null ? invoiceQuantity : quantity;
    }

    /** Teslim edilen miktarı döner; receivedQuantity null ise invoiceQty kadar geldi varsayılır. */
    public int resolvedReceivedQty() {
        if (receivedQuantity != null) return receivedQuantity;
        return resolvedInvoiceQty();
    }

    /** Eksik miktar (faturada olan ama gelmeyen). */
    public int shortageQty() {
        return Math.max(0, resolvedInvoiceQty() - resolvedReceivedQty());
    }
}
