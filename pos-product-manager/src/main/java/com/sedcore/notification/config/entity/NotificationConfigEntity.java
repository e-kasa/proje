package com.sedcore.notification.config.entity;

import com.sedcore.notification.entity.NotificationChannel;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Sprint 29 — Channel başına key-value config saklayıcısı.
 *
 * <p>Audit: {@code .wiki/sources/code-refs/2026-05-01-notification-config-save-audit.md}
 *
 * <p>Multi-tenant: {@link TOpenSimpleCompanyEntity} inherited Hibernate
 * {@code @Filter} ile {@code companyCode} otomatik filtrelenir. Her şirketin
 * kendi SMTP/Twilio credentials'ı olur.
 *
 * <p>Schema:
 * <pre>
 *   UNIQUE (company_code, config_channel, config_key)
 * </pre>
 *
 * <p>Sprint 29: EMAIL channel kullanılır (host, port, useTls, username,
 * password, from). Sprint 30+: SMS (provider, accountSid, authToken, ...).
 *
 * <p>Güvenlik: {@code encrypted=true} flag Sprint 30'da Jasypt entegrasyonu
 * için zemin. Sprint 29 plain text + WARN log.
 */
@Entity
@Table(name = "notification_configs",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_notification_configs_unique",
                        columnNames = {"company_code", "config_channel", "config_key"}
                )
        },
        indexes = {
                @Index(name = "idx_notification_configs_channel",
                        columnList = "company_code, config_channel")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationConfigEntity extends TOpenSimpleCompanyEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "config_channel", nullable = false, length = 16)
    private NotificationChannel configChannel;

    @Column(name = "config_key", nullable = false, length = 64)
    private String configKey;

    @Column(name = "config_value", columnDefinition = "TEXT")
    private String configValue;

    /**
     * Sprint 29: her zaman {@code false}. Sprint 30 Jasypt encryption ile
     * {@code true} → {@code configValue} AES şifreli (decrypt-on-read).
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean encrypted = false;

    @Version
    private Long version;
}
