package com.sedcore.common.enums;

public enum ReconcileEntityType {
    CUSTOMER("Müşteri"),
    SUPPLIER("Tedarikçi");

    private final String description;

    ReconcileEntityType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
