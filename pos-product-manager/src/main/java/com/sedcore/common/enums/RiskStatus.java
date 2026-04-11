package com.sedcore.common.enums;

/**
 * Risk Durumu Enum
 */
public enum RiskStatus {
    NORMAL("Normal"),             // Normal risk
    WARNING("Uyarı"),             // Uyarı seviyesi
    CRITICAL("Kritik"),           // Kritik risk
    BLOCKED("Bloke");             // Hesap bloke

    private final String description;

    RiskStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
