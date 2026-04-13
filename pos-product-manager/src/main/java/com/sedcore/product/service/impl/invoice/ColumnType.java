package com.sedcore.product.service.impl.invoice;

/**
 * Fatura tablosundaki sütun tipleri.
 */
public enum ColumnType {
    ROW_NUMBER,   // Sıra no
    CODE,         // Ürün kodu / Stok kodu / OEM / Barkod
    DESCRIPTION,  // Ürün adı / Açıklama / Malzeme
    QUANTITY,     // Miktar / Adet
    UNIT,         // Birim (Adet, Kg, Lt...)
    UNIT_PRICE,   // Birim fiyat
    VAT,          // KDV oranı (%)
    TOTAL         // Satır toplamı
}
