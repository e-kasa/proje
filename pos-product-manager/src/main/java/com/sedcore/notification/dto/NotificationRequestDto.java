package com.sedcore.notification.dto;

import com.sedcore.notification.entity.NotificationChannel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Sprint 25 — POST /api/v1/notifications/send istek body'si.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationRequestDto {

    @NotBlank(message = "eventType zorunlu")
    @Size(max = 64)
    private String eventType;

    @NotNull(message = "channel zorunlu")
    private NotificationChannel channel;

    @NotBlank(message = "recipient zorunlu")
    @Size(max = 256)
    private String recipient;

    @Size(max = 256)
    private String subject;

    @NotBlank(message = "body zorunlu")
    private String body;

    /** Opsiyonel — DB-stored template referansı (Sprint 27+ template engine). */
    @Size(max = 64)
    private String templateCode;
}
