package com.sedcore.notification.config.repository;

import com.sedcore.notification.config.entity.NotificationConfigEntity;
import com.sedcore.notification.entity.NotificationChannel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Sprint 29 — Notification config repository.
 *
 * <p>Multi-tenant filter (companyCode) Hibernate @Filter ile otomatik
 * (TOpenSimpleCompanyEntity inherited).
 */
@Repository
public interface NotificationConfigRepository
        extends JpaRepository<NotificationConfigEntity, String> {

    /** Tek channel için tüm key-value config kayıtları. */
    List<NotificationConfigEntity> findByConfigChannel(NotificationChannel channel);

    /** Channel + key tek kayıt — upsert için. */
    Optional<NotificationConfigEntity> findByConfigChannelAndConfigKey(
            NotificationChannel channel, String configKey);
}
