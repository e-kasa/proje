package com.sedcore.product.service.impl.invoice;

/**
 * Pozisyonel çıkarımla elde edilmiş tek bir tablo hücresini temsil eder.
 *
 * @param text   hücrenin birleştirilmiş metni (boşlukla ayrılmış fragment'lar)
 * @param xStart hücrenin sol kenar X koordinatı (ilk fragment'ın X'i)
 * @param xEnd   hücrenin sağ kenar X koordinatı (son fragment'ın sağ X'i)
 */
public record TableCell(String text, float xStart, float xEnd) {

    /** Hücre merkez X koordinatı (sütun karşılaştırması için). */
    public float centerX() {
        return (xStart + xEnd) / 2f;
    }

    /** Hücre metni trim edilmiş şekilde. */
    public String trimmedText() {
        return text == null ? "" : text.trim();
    }
}
