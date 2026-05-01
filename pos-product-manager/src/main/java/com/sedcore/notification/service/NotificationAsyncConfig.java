package com.sedcore.notification.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

/**
 * Sprint 25 — Notifications için izole {@code @Async} thread pool.
 *
 * <p>Default Spring executor (taskExecutor) yerine adlanmış
 * {@code notificationExecutor} kullanılır:
 * <ul>
 *   <li>Diğer @Async tüketicilerinden izole (saturation kontrol)
 *   <li>Boyut config-driven (notification.async.thread-pool.size)
 *   <li>Sprint 26'da RabbitMQ consumer'a geçince bu bean kaldırılır
 * </ul>
 */
@Configuration
public class NotificationAsyncConfig {

    @Value("${notification.async.thread-pool.size:5}")
    private int poolSize;

    @Value("${notification.async.queue-capacity:100}")
    private int queueCapacity;

    @Bean(name = "notificationExecutor")
    public Executor notificationExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(poolSize);
        executor.setMaxPoolSize(poolSize);
        executor.setQueueCapacity(queueCapacity);
        executor.setThreadNamePrefix("notif-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);
        executor.initialize();
        return executor;
    }
}
