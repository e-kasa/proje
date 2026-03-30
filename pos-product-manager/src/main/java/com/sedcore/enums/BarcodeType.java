package com.sedcore.enums;

public enum BarcodeType {
    EAN13("EAN-13", 13),
    EAN8("EAN-8", 8),
    UPC("UPC", 12),
    CODE128("Code 128", -1),
    QR_CODE("QR Code", -1),
    DATA_MATRIX("Data Matrix", -1),
    CODE39("Code 39", -1),
    ITF("ITF-14", 14);

    private final String displayName;
    private final int length;

    BarcodeType(String displayName, int length) {
        this.displayName = displayName;
        this.length = length;
    }

    public String getDisplayName() {
        return displayName;
    }

    public int getLength() {
        return length;
    }

    public boolean hasFixedLength() {
        return length > 0;
    }
}