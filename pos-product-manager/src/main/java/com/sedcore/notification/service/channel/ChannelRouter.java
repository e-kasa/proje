package com.sedcore.notification.service.channel;

import com.sedcore.notification.entity.NotificationChannel;
import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.exception.UnsupportedChannelException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Sprint 25 — {@link NotificationChannel} → uygun {@link NotificationChannelGateway}
 * dispatcher'ı.
 *
 * <p>Sprint 25'te yalnız EMAIL real. Diğer kanallar
 * {@link UnsupportedChannelException} fırlatır → status=FAILED + errorMessage.
 * Sprint 26+'da {@code SmsChannel}, Sprint 27+'da {@code WhatsAppChannel}
 * eklendikçe constructor injection genişler.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ChannelRouter {

    private final EmailChannel emailChannel;
    private final SmsChannel smsChannel;  // Sprint 26-A: aktif (SmsProvider abstraction)
    // Sprint 27: private final WhatsAppChannel whatsAppChannel;
    // Sprint 28: private final PushChannel pushChannel;

    public void send(NotificationEntity n) {
        switch (n.getChannel()) {
            case EMAIL -> emailChannel.send(n);
            case SMS -> smsChannel.send(n);
            case WHATSAPP -> throw new UnsupportedChannelException(
                    "WhatsApp kanalı Sprint 27'de aktif olacak.");
            case PUSH -> throw new UnsupportedChannelException(
                    "Push kanalı Sprint 28'de aktif olacak (FCM).");
            default -> throw new UnsupportedChannelException(
                    "Bilinmeyen kanal: " + n.getChannel());
        }
    }
}
