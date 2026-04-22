package com.sedcore.common.enums;

/**
 * Satın alma belgesi durumu.
 *
 * <pre>
 * COMPLETED  — tüm kalemler teslim alındı, fatura kapatıldı
 * PARTIAL    — eksik teslimat var, SupplierClaim açık
 * DISCOUNTED — eksik tutar tedarikçi iskontosu ile kapatıldı
 * CANCELLED  — satın alma iptal edildi
 * </pre>
 */
public enum PurchaseStatus {
    COMPLETED,
    PARTIAL,
    DISCOUNTED,
    CANCELLED
}
