package com.sedcore.notification.repository;

import com.sedcore.notification.entity.NotificationChannel;
import com.sedcore.notification.entity.NotificationEntity;
import com.sedcore.notification.entity.NotificationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Sprint 25 — Notification repository.
 *
 * <p>Multi-tenant filter (companyCode) Hibernate @Filter ile otomatik
 * (TOpenSimpleCompanyEntity inherited).
 */
@Repository
public interface NotificationRepository extends JpaRepository<NotificationEntity, String> {

    /** Hub/admin ekranı listesi (status filtreli, en yeni üste). */
    Page<NotificationEntity> findByStatusOrderByCreateTimeDesc(
            NotificationStatus status, Pageable pageable);

    Page<NotificationEntity> findAllByOrderByCreateTimeDesc(Pageable pageable);

    /**
     * Sprint 26+ scheduled job: PENDING/RETRYING ama retry_count limit altı
     * olan eski kayıtları yeniden tetiklemek için.
     */
    List<NotificationEntity> findByStatusAndRetryCountLessThan(
            NotificationStatus status, int maxRetryCount);

    /** Belirli bir alıcıya son N gün içinde gönderilen — rate limit benzeri. */
    long countByChannelAndRecipientAndStatus(
            NotificationChannel channel, String recipient, NotificationStatus status);
}
