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
}
