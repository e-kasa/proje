package com.sedcore.purchase.model;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

/**
 * Tedarikçi iskontosu / kredi notu uygulama isteği.
 *
 * <p>Senaryo: Faturada 10 kalem var, 8'i geldi. 2 kalemlik (200₺) eksiklik için
 * tedarikçi kredi notu düzenledi. Bu request ile o eksik tutar iskonto olarak kapatılır.</p>
 *
 * <p>İş kuralları (PurchaseServiceImpl.applyDiscount):</p>
 * <ul>
 *   <li>discountAmount ≤ purchase.shortageAmount olmalı</li>
 *   <li>İptal edilmiş satın alımlara uygulanamaz</li>
 *   <li>SupplierAccount'a credit kaydı yazılmaz — zaten shortageAmount için debit yazılmadı</li>
 *   <li>AccountTransaction(DISCOUNT) sadece audit amaçlı kaydedilir</li>
 * </ul>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseDiscountRequest {

    @NotNull(message = "İskonto tutarı zorunludur")
    @Positive(message = "İskonto tutarı pozitif olmalıdır")
    private BigDecimal discountAmount;

    /** Tedarikçinin düzenlediği kredi notu numarası (opsiyonel ama tavsiye edilir) */
    private String creditNoteNumber;

    private String notes;
}
