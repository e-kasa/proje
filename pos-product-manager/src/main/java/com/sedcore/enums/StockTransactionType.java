package com.sedcore.enums;

/**
 * Stok Hareket Tipi Enum
 */
enum StockTransactionType {
    PURCHASE("Satın Alma"),
    SALE("Satış"),
    RETURN_FROM_CUSTOMER("Müşteriden İade"),
    RETURN_TO_SUPPLIER("Tedarikçiye İade"),
    TRANSFER_IN("Transfer Giriş"),
    TRANSFER_OUT("Transfer Çıkış"),
    ADJUSTMENT_INCREASE("Düzeltme - Artış"),
    ADJUSTMENT_DECREASE("Düzeltme - Azalış"),
    PRODUCTION("Üretim"),
    CONSUMPTION("Tüketim");

    private final String description;

    StockTransactionType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }}