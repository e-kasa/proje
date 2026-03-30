package com.sedcore.enums;

/**
 * Ödeme Tipi Enum
 */
public enum PaymentType {
    CASH("Nakit"),                    // Nakit
    CREDIT_CARD("Kredi Kartı"),       // Kredi kartı
    DEBIT_CARD("Banka Kartı"),        // Banka kartı
    BANK_TRANSFER("Havale/EFT"),      // Havale/EFT
    CHECK("Çek"),                     // Çek
    PROMISSORY_NOTE("Senet"),         // Senet
    MOBILE_PAYMENT("Mobil Ödeme"),    // Mobil ödeme (QR, vb.)
    OTHER("Diğer");                   // Diğer

    private final String description;

    PaymentType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
