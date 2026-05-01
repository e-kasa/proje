package com.sedcore.notification.entity;

/**
 * Sprint 25 — Bildirim kanalı.
 *
 * <p>EMAIL Sprint 25'te real (mevcut SMTP üzerinden).
 * SMS Sprint 26'da Twilio entegrasyonu ile aktive olur.
 * WHATSAPP + PUSH Sprint 27-28 placeholder.
 */
public enum NotificationChannel {
    EMAIL,
    SMS,
    WHATSAPP,
    PUSH
}
