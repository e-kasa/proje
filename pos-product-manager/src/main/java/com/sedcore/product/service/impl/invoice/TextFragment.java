package com.sedcore.product.service.impl.invoice;

/**
 * PDF sayfasında tek bir karakter/kelime parçasının konum bilgisi.
 *
 * @param text  karakter veya kelimenin metni
 * @param x     sol kenar (PDF koordinatı, nokta cinsinden)
 * @param y     taban çizgisi (PDF koordinatı — PDF'de Y yukarı doğru artar)
 * @param width genişlik (nokta cinsinden)
 */
public record TextFragment(String text, float x, float y, float width) {

    /** Sağ kenar X koordinatı. */
    public float xEnd() {
        return x + width;
    }
}
