package com.sedcore.notification.service.channel.sms;

import com.sedcore.notification.exception.PermanentNotificationException;
import com.sedcore.notification.exception.TransientNotificationException;

/**
 * Sprint 26-A — SMS sağlayıcı soyutlaması.
 *
 * <p>Implementasyonlar (config: {@code notification.sms.provider}):
 * <ul>
 *   <li>{@code noop} — {@link NoopSmsProvider} (default; credentials yokken)
 *   <li>{@code twilio} — {@link TwilioSmsProvider}
 *   <li>{@code netgsm} — Sprint 27 (Türkiye yerel)
 *   <li>{@code iletimerkezi} — Sprint 27+ (Türkiye toplu)
 * </ul>
 *
 * <p>Hata semantiği:
 * <ul>
 *   <li>4xx (invalid recipient, bad request) → {@link PermanentNotificationException}
 *       → status=FAILED, retry yok
 *   <li>5xx / network / timeout → {@link TransientNotificationException}
 *       → retry (Sprint 25 deliverAsync loop)
 * </ul>
 */
public interface SmsProvider {

    /**
     * @param to E.164 format telefon ("+905551234567")
     * @param body SMS metni (max 160 char Türkçe non-Unicode, 70 char Unicode)
     * @return Provider message ID (Twilio messageSid, vb.) — metadata için saklanır
     */
    String sendSms(String to, String body);

    /** Provider adı (log + metadata için). */
    String providerName();
}
