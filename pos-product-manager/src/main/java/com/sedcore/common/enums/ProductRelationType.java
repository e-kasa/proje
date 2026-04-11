package com.sedcore.common.enums;

/**
 * Ürün İlişki Tipi Enum
 *
 * Ürünler arasındaki ilişkilerin tanımlandığı enum
 */
public enum ProductRelationType {
    SIMILAR("Benzer Ürün"),           // Benzer ürün (civata M10 → civata M12)
    ALTERNATIVE("Alternatif Ürün"),  // Alternatif ürün (marka A → marka B)
    COMPLEMENTARY("Tamamlayıcı");    // Tamamlayıcı ürün (civata → civata pulu)

    private final String description;

    ProductRelationType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
