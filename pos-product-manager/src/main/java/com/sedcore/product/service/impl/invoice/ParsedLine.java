package com.sedcore.product.service.impl.invoice;

/**
 * Fatura satırından çıkarılan ham bilgiler.
 * DocumentAnalyzeServiceImpl.extractLineInfo() ve ColumnAwareLineParser tarafından doldurulur.
 */
public class ParsedLine {
    public String name;
    public String code;
    public String codeType;   // "BARCODE" | "OEM" | null
    public Double quantity;
    public Double unitPrice;
    public String unit;       // "ADET" | "KG" | "LT" | null
    public Double vatRate;    // 8.0 | 18.0 | 20.0 | null
    public Boolean vatIncluded; // null = bilinmiyor
    public Double totalPrice; // satır toplamı | null
}
