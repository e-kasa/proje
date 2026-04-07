package com.sedcore.enums;

public enum StockMovementType {

    PURCHASE_IN,           // Satın alımdan stok girişi
    PURCHASE_RETURN_OUT,   // Tedarikçiye iade çıkışı
    SALE_OUT,              // Satıştan stok çıkışı
    SALE_RETURN_IN,        // Müşteri iadesinden stok girişi
    SALE_CANCEL_IN,        // İptal edilen satıştan stok girişi (geri alma)
    TRANSFER_IN,           // Depo transferi girişi
    TRANSFER_OUT,          // Depo transferi çıkışı
    ADJUSTMENT_IN,         // Manuel düzeltme girişi
    ADJUSTMENT_OUT         // Manuel düzeltme çıkışı
}
