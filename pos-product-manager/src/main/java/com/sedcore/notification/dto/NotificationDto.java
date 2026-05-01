package com.sedcore.notification.dto;

import com.sedcore.notification.entity.NotificationChannel;
import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.entity.NotificationStatus;
import lombok.Builder;
import lombok.Data;

import java.time.Instant;

/**
 * Sprint 25 — Response body (entity → DTO projeksiyonu).
 *
 * <p>{@code body} hassas içerik içerebilir (kişisel mesaj/credential),
 * istemciye geri dönerken kısaltma/maskeleme yok — admin/sahibi gördüğü için
 * tam metin döner. Sprint 28'de role-based maskeleme değerlendirilir.
 */
@Data
@Builder
public class NotificationDto {

    private String id;
    private String eventType;
    private NotificationChannel channel;
    private String recipient;
    private String subject;
    private String body;
    private NotificationStatus status;
    private String errorMessage;
    private int retryCount;
    private String templateCode;
    private Instant sentAt;
    private Instant createdAt;

    public static NotificationDto fromEntity(NotificationEntity e) {
        return NotificationDto.builder()
                .id(e.getId())
                .eventType(e.getEventType())
                .channel(e.getChannel())
                .recipient(e.getRecipient())
                .subject(e.getSubject())
                .body(e.getBody())
                .status(e.getStatus())
                .errorMessage(e.getErrorMessage())
                .retryCount(e.getRetryCount())
                .templateCode(e.getTemplateCode())
                .sentAt(e.getSentAt())
                .createdAt(e.getCreateTime() != null ? e.getCreateTime().toInstant() : null)
                .build();
    }
}
