package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Doküman analizinde mevcut ürün eşleşmesi yapıldığında, ürünün tüm variant
 * özetlerini Flutter'a taşımak için kullanılan DTO.
 *
 * <p>Kullanım senaryosu: Fatura "3 Numara Siyah Gömlek" satırıyla eşleşirse,
 * kullanıcı kartta diğer variantları ("4 Numara Siyah", "5 Numara Kırmızı")
 * görebilmeli ki stok/raf kararı verebilsin.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchedVariantSummary {

    /** Variant ID */
    private String variantId;

    /** Variant SKU */
    private String sku;

    /** Variant adı (ör. "Gömlek - 42 Siyah") */
    private String name;

    /** Attributes map (ör. {"Numara": "42", "Renk": "Siyah"}) */
    private Map<String, String> attributes;

    /** Anlık toplam stok (tüm lokasyonlar) */
    private Double currentStock;

    /** Aktif satış fiyatı */
    private BigDecimal salePrice;

    /** Raf kodu */
    private String shelfLocationCode;

    /** Bu variant, fatura satırıyla eşleşen midir? */
    private boolean isMatched;
}
