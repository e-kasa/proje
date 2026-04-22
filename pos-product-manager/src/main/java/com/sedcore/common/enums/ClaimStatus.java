package com.sedcore.common.enums;

/**
 * Tedarikçi alacak talebi durumu.
 *
 * <pre>
 * OPEN               — çözüm bekleniyor
 * RESOLVED_DELIVERY  — eksik mallar bir sonraki irsaliyeyle teslim edildi
 * RESOLVED_DISCOUNT  — tedarikçi kredi notu / iskonto ile kapattı
 * RESOLVED_RETURN    — nakit para iadesi yapıldı
 * CANCELLED          — talep iptal edildi (hatalı açılmış)
 * </pre>
 */
public enum ClaimStatus {
    OPEN,
    RESOLVED_DELIVERY,
    RESOLVED_DISCOUNT,
    RESOLVED_RETURN,
    CANCELLED
}
