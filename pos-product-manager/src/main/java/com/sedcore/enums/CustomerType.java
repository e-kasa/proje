package com.sedcore.enums;

/**
 * Müşteri Tipi Enum
 */
public enum CustomerType {
    INDIVIDUAL("Bireysel"),      // Bireysel müşteri
    CORPORATE("Kurumsal"),        // Kurumsal müşteri
    DEALER("Bayi"),               // Bayi
    WHOLESALER("Toptancı");       // Toptancı

    private final String description;

    CustomerType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
