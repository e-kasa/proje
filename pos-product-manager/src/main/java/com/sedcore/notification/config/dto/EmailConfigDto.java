package com.sedcore.notification.config.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sprint 29 — Email SMTP config DTO.
 *
 * <p>GET response'unda {@code password} **maskelenmiş** döner ({@code "****"}).
 * PUT request'inde {@code password} null veya boş ise mevcut değer korunur
 * (kısmi update).
 *
 * <p>Backend storage: {@code notification_configs} key-value tablosu,
 * channel=EMAIL.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmailConfigDto {

    /** SMTP sunucu adresi: smtp.gmail.com, smtp.sendgrid.net, ... */
    @Size(max = 256)
    private String host;

    /** Port: 587 (STARTTLS), 465 (SSL), 25 (legacy) */
    private Integer port;

    /** TLS/SSL kullan. */
    private Boolean useTls;

    /** SMTP username (genelde from email ile aynı). */
    @Size(max = 256)
    private String username;

    /**
     * SMTP password / app password.
     * - GET: maskelenmiş "****" (mevcut config var ise) veya null
     * - PUT: null/boş = mevcudu koru; doluysa güncelle
     */
    @Size(max = 512)
    private String password;

    /** Gönderen adı (From): "SEDCORE POS <noreply@sedcore.com>" */
    @Size(max = 256)
    private String from;

    /** EMAIL kanalı master enabled (mevcut mail.enabled override). */
    private Boolean enabled;

    /** "Kaydedildi" sonrası UI mesajı için (GET response'unda dolu). */
    @NotBlank
    @Size(max = 64)
    private String channel;  // her zaman "EMAIL" — discriminator
}
