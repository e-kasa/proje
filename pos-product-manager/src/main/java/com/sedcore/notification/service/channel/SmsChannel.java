package com.sedcore.notification.service.channel;

import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.service.channel.sms.SmsProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Sprint 26-A — SMS kanalı: aktif {@link SmsProvider}'a delege eder.
 *
 * <p>Provider seçimi {@code notification.sms.provider} property ile yapılır
 * (noop / twilio / netgsm / iletimerkezi). Spring context'te yalnız bir
 * provider impl bean'i olur (`@ConditionalOnProperty`).
 *
 * <p>Provider'ın gönderim sonucu döndürdüğü message ID,
 * {@link NotificationEntity#setMetadata(String)} alanına basit JSON formatında
 * yazılır → audit/troubleshooting (Twilio messageSid ile log eşleştirme).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SmsChannel implements NotificationChannelGateway {

    private final SmsProvider smsProvider;

    @Override
    public void send(NotificationEntity n) {
        String providerMessageId = smsProvider.sendSms(n.getRecipient(), n.getBody());
        n.setMetadata(buildMetadata(providerMessageId));
        log.info("SMS gönderildi (provider={}): notificationId={}, to={}, providerMessageId={}",
                smsProvider.providerName(), n.getId(), n.getRecipient(), providerMessageId);
    }

    private String buildMetadata(String providerMessageId) {
        // Sprint 26-A: basit JSON string. Sprint 26-B'de JsonType + Map<String,Object>
        return String.format(
                "{\"provider\":\"%s\",\"providerMessageId\":\"%s\"}",
                escape(smsProvider.providerName()),
                escape(providerMessageId));
    }

    private static String escape(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
