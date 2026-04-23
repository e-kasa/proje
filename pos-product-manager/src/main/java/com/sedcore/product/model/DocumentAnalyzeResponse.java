package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Fatura/İrsaliye belge analizi yanıtı.
 * Belgeden çıkarılan ürün kalemlerinin sistemdeki karşılıkları döner.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentAnalyzeResponse {

    /** Yüklenen dosyanın adı */
    private String fileName;

    /** Belgede bulunan toplam ürün kalemi sayısı */
    private int totalItems;

    /** Sistemde bulunan (eşleşen) kalem sayısı */
    private int foundItems;

    /** Sistemde bulunmayan (yeni) kalem sayısı */
    private int notFoundItems;

    /** Ürün kalemlerinin analiz sonuçları */
    private List<DocumentItemResult> items;

    /**
     * true → belge taranmış/görüntü tabanlıydı, Python OCR ile işlendi.
     * Flutter bu alanı uyarı banner'ı için kullanır.
     */
    private boolean scannedPdf;

    /**
     * Parse yöntemi — debug ve loglama için.
     * "POSITIONAL" | "REGEX" | "OCR"
     */
    private String parseMethod;

    /** Faturadan çıkarılan fatura numarası (Python header regex) — null olabilir */
    private String invoiceNo;

    /** Faturadan çıkarılan fatura tarihi (ham string, "15.04.2026" vb.) — null olabilir */
    private String invoiceDate;

    /** Faturadan çıkarılan satıcı firma adı — null olabilir */
    private String supplierName;
}
