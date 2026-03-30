package com.sedcore.enums;

/**
 * Medya Tipi Enum
 */
public enum MediaType {
    IMAGE("Görsel"),
    VIDEO("Video"),
    DOCUMENT("Belge"),
    MODEL_3D("3D Model");

    private final String description;

    MediaType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
