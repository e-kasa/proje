package com.sedcore.notification.service.channel.sms;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Sprint 26-A — Default SMS provider: gerçek gönderim yok, sadece log.
 *
 * <p>Aktivasyon koşulu: {@code notification.sms.provider} unset veya {@code noop}.
 * {@code matchIfMissing = true} → application.properties'te SMS provider
 * tanımlanmamışsa otomatik bu provider seçilir.
 *
 * <p>Avantajları:
 * <ul>
 *   <li>Twilio credentials yokken backend ayağa kalkar (NPE/IllegalState yok)
 *   <li>Frontend hookup test edilebilir (UI → 202 + status=SENT akışı çalışır)
 *   <li>SMS body log'da görünür → manuel doğrulama
 *   <li>Twilio aktive edildiğinde tek property değişikliği:
 *       {@code notification.sms.provider=twilio}
 * </ul>
 */
@Component
@ConditionalOnProperty(
        name = "notification.sms.provider",
        havingValue = "noop",
        matchIfMissing = true)
@Slf4j
public class NoopSmsProvider implements SmsProvider {

    @Override
    public String sendSms(String to, String body) {
        String fakeId = "noop-" + UUID.randomUUID();
        log.info("[NOOP-SMS] Gerçek SMS gönderilmedi. to={}, bodyLen={}, fakeMessageId={}",
                to, body != null ? body.length() : 0, fakeId);
        return fakeId;
    }

    @Override
    public String providerName() {
        return "noop";
    }
}
