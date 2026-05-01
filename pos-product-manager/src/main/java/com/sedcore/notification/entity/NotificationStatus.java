package com.sedcore.notification.entity;

/**
 * Sprint 25 — Bildirim durumu.
 *
 * <p>Geçişler:
 * <pre>
 *   PENDING ─→ RETRYING ─→ SENT
 *      │           │
 *      └───────────┴─→ FAILED  (retry_count == max sonra)
 * </pre>
 */
public enum NotificationStatus {
    /** İlk persist edildi, henüz gönderilmedi. */
    PENDING,

    /** Async deliver çağrıldı, retry sürecinde (retry_count < max). */
    RETRYING,

    /** Başarıyla gönderildi (sentAt doldu). */
    SENT,

    /** Retry tükendi veya kalıcı hata (errorMessage doldu). */
    FAILED
}
