package com.sedcore.common.enums;

/**
 * Ürün Durum Enum
 */
public enum ProductStatus {
    DRAFT("Taslak"),
    ACTIVE("Aktif"),
    INACTIVE("Pasif"),
    OUT_OF_STOCK("Stokta Yok"),
    DISCONTINUED("Üretimi Durmuş"),
    ARCHIVED("Arşivlenmiş");

    private final String description;

    ProductStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
