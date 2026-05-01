package com.sedcore.notification.service.channel;

import com.sedcore.notification.entity.NotificationEntity;

/**
 * Sprint 25 — Channel-specific gönderim soyutlaması.
 *
 * <p>Implementasyonlar:
 * <ul>
 *   <li>{@code EmailChannel} — Sprint 25 (mevcut SMTP {@code EmailService}'i wrap)
 *   <li>{@code SmsChannel} — Sprint 26 (Twilio entegrasyonu)
 *   <li>{@code WhatsAppChannel} — Sprint 27 (Twilio WhatsApp)
 *   <li>{@code PushChannel} — Sprint 28 (FCM)
 * </ul>
 *
 * <p>Hata akışı:
 * <ul>
 *   <li>Geçici sorun → {@code TransientNotificationException} fırlat → retry
 *   <li>Kalıcı sorun → {@code PermanentNotificationException} fırlat → FAILED
 * </ul>
 */
public interface NotificationChannelGateway {

    /**
     * Gerçek gönderim. Başarılı olursa sessizce döner; başarısız olursa
     * {@link com.sedcore.notification.exception.TransientNotificationException}
     * veya {@link com.sedcore.notification.exception.PermanentNotificationException}
     * fırlatır.
     */
    void send(NotificationEntity notification);
}
