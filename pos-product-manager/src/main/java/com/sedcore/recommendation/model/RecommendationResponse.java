package com.sedcore.recommendation.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.util.List;
import java.util.Map;

/**
 * Önerilen Ürün Response DTO
 *
 * POS ekranında kasiyere gösterilen ürün önerileri
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RecommendationResponse {

    /**
     * Ürün ID
     */
    private String id;

    /**
     * Ürün adı
     */
    private String name;

    /**
     * SKU (stok kodu)
     */
    private String sku;

    /**
     * Variantlar (fiyat, resim vb.)
     */
    private List<Map<String, Object>> variants;

    /**
     * Satış fiyatı
     */
    private Double basePrice;

    /**
     * Maliyet fiyatı — kâr hesaplaması için
     */
    private Double costPrice;

    /**
     * Ürün resmi URL
     */
    private String imageUrl;

    /**
     * Kategori
     */
    private String categoryId;

    /**
     * Marka
     */
    private String brand;

    /**
     * Stok bilgisi
     */
    private Integer stock;

    // ─── Önerme İlişkili Alanlar ───

    /**
     * Önerme kaynağı:
     * - "FREQUENTLY_BOUGHT_TOGETHER": Satış verisinden gelen
     * - "SIMILAR_PRODUCT": Benzer ürün (manuel)
     * - "ALTERNATIVE_PRODUCT": Alternatif (manuel)
     * - "COMPLEMENTARY_PRODUCT": Tamamlayıcı (manuel)
     */
    private String recommendationType;

    /**
     * Neden önerildi (kullanıcı görmesi için)
     * Örnek: "Sıkça birlikte satılır" veya "Benzer ürün"
     */
    private String reason;

    /**
     * Ağırlık / Sıklık (ne kadar uygun bir öneri)
     * Birlikte satılan: kaç kez satılmış
     * Manuel: weight (1-10)
     */
    private Integer relevanceScore;

    /**
     * Sepete eklenecek ürün gerçekten bu mı?
     * (varyant seçimi için gerekirse true olacak)
     */
    private Boolean requiresVariantSelection;

    /**
     * Stok durumu
     */
    private String stockStatus; // "IN_STOCK", "LOW_STOCK", "OUT_OF_STOCK"

    /**
     * QR / Barkod (sepete hızlı ekleme için)
     */
    private String barcode;

    /**
     * Sepet kurulmuşsa bu önerinin ürün ID'si (API çağrında varyantId olur)
     */
    private String cartLineId;
}
