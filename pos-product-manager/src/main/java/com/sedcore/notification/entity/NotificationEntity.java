package com.sedcore.notification.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * Sprint 25 — SMS/Email/WhatsApp bildirim kaydı.
 *
 * <p>Audit dosyası: {@code .wiki/sources/code-refs/2026-05-01-notifications-system-audit.md}<br>
 * Mimari sentez: {@code .wiki/syntheses/notifications-system-design.md}
 *
 * <p>Multi-tenant: {@link TOpenSimpleCompanyEntity} inherited Hibernate
 * {@code @Filter} ile {@code companyCode} otomatik filtrelenir
 * (CompanyContextFilter).
 *
 * <p>Akış: PENDING → RETRYING → SENT (mutlu yol) | FAILED (retry tükenince).
 *
 * <p>Channel:
 * <ul>
 *   <li>EMAIL — Sprint 25 mevcut {@code EmailService} (SMTP) üzerinden real
 *   <li>SMS — Sprint 26 Twilio entegrasyonu
 *   <li>WHATSAPP / PUSH — Sprint 27-28 placeholder
 * </ul>
 */
@Entity
@Table(name = "notifications",
       indexes = {
           @Index(name = "idx_notifications_status_created", columnList = "status, create_time"),
           @Index(name = "idx_notifications_company_recipient",
                  columnList = "company_code, recipient")
       })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationEntity extends TOpenSimpleCompanyEntity {

    /** Domain olayı: "SALE_CREATED", "PAYMENT_DUE", "STOCK_LOW", "TEST", ... */
    @Column(name = "event_type", nullable = false, length = 64)
    private String eventType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private NotificationChannel channel;

    /** Telefon numarası (SMS/WhatsApp) veya email adresi. */
    @Column(nullable = false, length = 256)
    private String recipient;

    /** Email için subject (SMS/WhatsApp'ta null). */
    @Column(length = 256)
    private String subject;

    /** Gönderilecek metin (HTML email için Sprint 27+ template engine eklenecek). */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    @Builder.Default
    private NotificationStatus status = NotificationStatus.PENDING;

    /** Son hata mesajı (FAILED veya RETRYING durumunda). */
    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    /** Toplam denene sayısı (max-attempts ile karşılaştırılır). */
    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private int retryCount = 0;

    /** DB-stored template referansı — Sprint 27+ template engine için. */
    @Column(name = "template_code", length = 64)
    private String templateCode;

    /** Başarılı gönderim zamanı (status=SENT olduğunda doldurulur). */
    @Column(name = "sent_at")
    private Instant sentAt;

    /**
     * Channel-specific extra alanlar (JSON string).
     *
     * <p>Örn. SMS için Twilio messageSid, email için SMTP messageId.
     * Sprint 25'te basit text kolonu — Sprint 26+'da JsonType'a yükseltilebilir.
     */
    @Column(columnDefinition = "TEXT")
    private String metadata;

    @Version
    private Long version;

    /** PENDING → RETRYING geçiş helper'ı. */
    public void markRetrying() {
        this.status = NotificationStatus.RETRYING;
    }

    /** Başarılı gönderim — sentAt + status set eder. */
    public void markSent() {
        this.status = NotificationStatus.SENT;
        this.sentAt = Instant.now();
        this.errorMessage = null;
    }

    /** Kalıcı hata — FAILED + errorMessage. */
    public void markFailed(String error) {
        this.status = NotificationStatus.FAILED;
        this.errorMessage = error;
    }

    /** Geçici hata — retry_count++ + errorMessage. */
    public void recordTransientError(String error) {
        this.retryCount = this.retryCount + 1;
        this.errorMessage = error;
    }
}
