package com.sedcore.common.enums;

/**
 * Kategori Özellik Tipleri
 * Amazon benzeri dinamik özellik sistemi için
 */
public enum AttributeType {
    /**
     * Metin - Serbest metin girişi
     * Örn: Açıklama, Notlar
     */
    TEXT,

    /**
     * Sayı - Numerik değer
     * Örn: Ağırlık, Boyut
     */
    NUMBER,

    /**
     * Tekli Seçim - Dropdown listeden tek seçim
     * Örn: Marka, Renk, Beden
     */
    SELECT,

    /**
     * Çoklu Seçim - Birden fazla seçim
     * Örn: Özellikler (Su Geçirmez, Darbe Emici)
     */
    MULTI_SELECT,

    /**
     * Boolean - Evet/Hayır
     * Örn: Garantili mi?, Ücretsiz Kargo?
     */
    BOOLEAN,

    /**
     * Tarih - Tarih seçimi
     * Örn: Üretim Tarihi, Son Kullanma Tarihi
     */
    DATE,

    /**
     * Aralık - Min-Max değer aralığı
     * Örn: Fiyat Aralığı, Yaş Aralığı
     */
    RANGE,

    /**
     * Renk - Renk seçici
     * Hex kod ile renk
     */
    COLOR,

    /**
     * URL - Web adresi
     * Örn: Video URL, Dokümantasyon Linki
     */
    URL,

    /**
     * E-posta - Email adresi
     */
    EMAIL,

    /**
     * Telefon - Telefon numarası
     */
    PHONE
}
