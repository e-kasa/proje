package com.sedcore.enums;

/**
 * Cari Hesap Hareket Tipi Enum
 */
public enum TransactionType {
    SALE("Satis"),                          // Musteriye satis (BORC - musteri borclanir)
    PURCHASE("Satin Alma"),                 // Tedarikciden alim (BORC - biz borclaniyoruz)
    PAYMENT("Odeme"),                       // Odeme alma (ALACAK)
    SUPPLIER_PAYMENT("Tedarikci Odemesi"), // Tedarikciye odeme (ALACAK - borcumuz azalir)
    RETURN("Iade"),                         // Musteriden iade (ALACAK)
    SUPPLIER_RETURN("Tedarikciye Iade"),   // Tedarikciye iade (ALACAK - borcumuz azalir)
    DISCOUNT("Indirim"),                    // Indirim (ALACAK)
    LATE_FEE("Gecikme Faizi"),             // Gecikme faizi (BORC)
    ADJUSTMENT_DEBIT("Duzeltme - Borc"),   // Manuel borc duzeltme
    ADJUSTMENT_CREDIT("Duzeltme - Alacak"), // Manuel alacak duzeltme
    REFUND("Geri Odeme"),                   // Para iadesi (ALACAK)
    COLLECTION("Tahsilat");                 // Tahsilat (ALACAK)

    private final String description;

    TransactionType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }

    public boolean isDebit() {
        return this == SALE || this == PURCHASE || this == LATE_FEE || this == ADJUSTMENT_DEBIT;
    }

    public boolean isCredit() {
        return this == PAYMENT || this == SUPPLIER_PAYMENT
            || this == RETURN || this == SUPPLIER_RETURN
            || this == DISCOUNT || this == ADJUSTMENT_CREDIT
            || this == REFUND || this == COLLECTION;
    }
}
