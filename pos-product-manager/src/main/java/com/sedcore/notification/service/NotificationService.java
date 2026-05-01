package com.sedcore.notification.service;

import com.sedcore.notification.dto.NotificationDto;
import com.sedcore.notification.dto.NotificationRequestDto;
import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.entity.NotificationStatus;
import com.sedcore.notification.exception.PermanentNotificationException;
import com.sedcore.notification.exception.TransientNotificationException;
import com.sedcore.notification.repository.NotificationRepository;
import com.sedcore.notification.service.channel.ChannelRouter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Sprint 25 — Bildirim orchestration servisi.
 *
 * <p>Akış:
 * <ol>
 *   <li>{@link #queue(NotificationRequestDto)} — sync persist (PENDING) +
 *       async deliver tetikleme. HTTP cevabı 202 Accepted.
 *   <li>{@link #deliver(String)} — {@code @Async} thread pool'da çalışır.
 *       Loop içinde retry (max-attempts kadar). Sprint 26'da RabbitMQ
 *       consumer'a refactor edilir.
 * </ol>
 *
 * <p>Sprint 25 sade in-memory retry: <b>tek instance</b> başına çalışır.
 * Çoklu instance için Sprint 26 RabbitMQ shifti zorunlu.
 *
 * <p>Multi-tenant: {@code companyCode} {@link com.sedcore.common.context.CompanyContext}'ten
 * otomatik alınır (TOpenSimpleCompanyEntity inherited).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository repo;
    private final ChannelRouter channelRouter;

    @Value("${notification.retry.max-attempts:3}")
    private int maxAttempts;

    @Value("${notification.retry.initial-delay-ms:5000}")
    private long initialDelayMs;

    @Value("${notification.retry.multiplier:2.0}")
    private double backoffMultiplier;

    /**
     * Public API — frontend POST /api/v1/notifications/send.
     *
     * <p>Sync persist (PENDING) + async dispatch. Çağıran 202 Accepted alır,
     * gerçek gönderim arka planda devam eder.
     */
    @Transactional
    public NotificationDto queue(NotificationRequestDto req) {
        NotificationEntity entity = NotificationEntity.builder()
                .eventType(req.getEventType())
                .channel(req.getChannel())
                .recipient(req.getRecipient())
                .subject(req.getSubject())
                .body(req.getBody())
                .templateCode(req.getTemplateCode())
                .status(NotificationStatus.PENDING)
                .retryCount(0)
                .build();
        NotificationEntity saved = repo.save(entity);
        log.info("Notification kuyruğa alındı: id={}, channel={}, recipient={}, eventType={}",
                saved.getId(), saved.getChannel(), saved.getRecipient(), saved.getEventType());
        // Sprint 25: @Async direct dispatch
        // Sprint 26: rabbitTemplate.convertAndSend(...)
        deliverAsync(saved.getId());
        return NotificationDto.fromEntity(saved);
    }

    /**
     * Sprint 25 — In-memory async deliver loop.
     *
     * <p>Spring {@code @Retryable} yerine manuel loop kullanıldı çünkü:
     * <ul>
     *   <li>Persistence (status update) her denemede yapılmalı
     *   <li>Backoff parametreleri config-driven
     *   <li>Sprint 26'da RabbitMQ ack/nack mekaniğine geçiş daha kolay
     * </ul>
     */
    @Async("notificationExecutor")
    public void deliverAsync(String notificationId) {
        long delay = initialDelayMs;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            Optional<NotificationEntity> opt = repo.findById(notificationId);
            if (opt.isEmpty()) {
                log.warn("Notification kayıt bulunamadı (silinmiş?): id={}", notificationId);
                return;
            }
            NotificationEntity n = opt.get();
            if (n.getStatus() == NotificationStatus.SENT) {
                log.debug("Notification zaten SENT, retry atlanıyor: id={}", notificationId);
                return;
            }
            n.markRetrying();
            repo.save(n);
            try {
                channelRouter.send(n);
                n.markSent();
                repo.save(n);
                log.info("Notification gönderildi: id={}, attempt={}", notificationId, attempt);
                return;
            } catch (PermanentNotificationException e) {
                log.warn("Kalıcı hata, retry yok: id={}, error={}", notificationId, e.getMessage());
                n.markFailed(e.getMessage());
                repo.save(n);
                return;
            } catch (TransientNotificationException e) {
                log.warn("Geçici hata, attempt {}/{}: id={}, error={}",
                        attempt, maxAttempts, notificationId, e.getMessage());
                n.recordTransientError(e.getMessage());
                repo.save(n);
                if (attempt == maxAttempts) {
                    n.markFailed("Retry tükendi: " + e.getMessage());
                    repo.save(n);
                    log.error("Retry tükendi, FAILED: id={}", notificationId);
                    return;
                }
                sleepQuiet(delay);
                delay = (long) (delay * backoffMultiplier);
            } catch (Exception e) {
                log.error("Beklenmeyen hata: id={}", notificationId, e);
                n.markFailed("Beklenmeyen: " + e.getClass().getSimpleName() + " " + e.getMessage());
                repo.save(n);
                return;
            }
        }
    }

    /** Hub/admin ekranı listesi — tüm statü veya belirli statü filtreli. */
    public Page<NotificationDto> list(NotificationStatus status, Pageable pageable) {
        Page<NotificationEntity> page = (status == null)
                ? repo.findAllByOrderByCreateTimeDesc(pageable)
                : repo.findByStatusOrderByCreateTimeDesc(status, pageable);
        return page.map(NotificationDto::fromEntity);
    }

    private static void sleepQuiet(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }
}
