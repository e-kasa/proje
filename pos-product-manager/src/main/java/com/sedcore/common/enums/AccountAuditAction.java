package com.sedcore.common.enums;

/**
 * Sprint 30 — AccountAuditLog action tipi.
 *
 * <ul>
 *   <li>{@code CREATE} — entity yaratıldı (yeni müşteri/tedarikçi)
 *   <li>{@code UPDATE} — alan değişikliği (her alan için ayrı kayıt)
 *   <li>{@code DELETE} — soft/hard delete
 *   <li>{@code RESTORE} — soft delete geri alma
 * </ul>
 */
public enum AccountAuditAction {
    CREATE,
    UPDATE,
    DELETE,
    RESTORE
}
