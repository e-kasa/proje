package com.sedcore.common.enums;

public enum ReconcileScope {
    SINGLE("Tek hesap"),
    ALL("Toplu reconcile");

    private final String description;

    ReconcileScope(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
