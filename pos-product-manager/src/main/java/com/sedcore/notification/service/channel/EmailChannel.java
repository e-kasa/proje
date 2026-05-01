package com.sedcore.notification.service.channel;

import com.sedcore.common.notification.EmailService;
import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.exception.PermanentNotificationException;
import com.sedcore.notification.exception.TransientNotificationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Sprint 25 — Email kanalı: mevcut Sprint 5 {@link EmailService}'i wrap eder.
 *
 * <p>{@code EmailService.sendWithAttachment(...)} {@code boolean} döndürür;
 * {@code false} olduğunda transient hata kabul edilir (SMTP timeout, geçici
 * config sorunu gibi). Kalıcı hata için (invalid recipient) Sprint 27'de
 * {@link EmailService}'e detaylı exception mapping eklenecek.
 *
 * <p>Sprint 25 sınırlamaları:
 * <ul>
 *   <li>HTML body desteği yok (plaintext)
 *   <li>Attachment yok
 *   <li>Template engine yok
 * </ul>
 * Bu sınırlamalar Sprint 27'de genişletilir.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class EmailChannel implements NotificationChannelGateway {

    private final EmailService emailService;

    @Override
    public void send(NotificationEntity n) {
        if (!emailService.isEnabled()) {
            log.warn("Email kanalı devre dışı (mail.enabled=false). notificationId={}",
                    n.getId());
            throw new PermanentNotificationException(
                    "Email kanalı devre dışı (mail.enabled=false)");
        }
        String subject = n.getSubject() != null && !n.getSubject().isBlank()
                ? n.getSubject()
                : "(Konu yok)";
        boolean ok = emailService.sendWithAttachment(
                n.getRecipient(),
                subject,
                n.getBody(),
                null,
                null);
        if (!ok) {
            throw new TransientNotificationException(
                    "EmailService.sendWithAttachment dönüş false: SMTP geçici hata olabilir");
        }
        log.info("Email gönderildi: notificationId={}, to={}, subject={}",
                n.getId(), n.getRecipient(), subject);
    }
}
