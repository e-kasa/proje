package com.sedcore.notification.config.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.notification.config.entity.NotificationConfigEntity;
import com.sedcore.notification.config.repository.NotificationConfigRepository;
import com.sedcore.notification.entity.NotificationChannel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sprint 29 — Channel-based key-value config saklayıcısı.
 *
 * <p>Cache stratejisi: tenant + channel anahtarlı in-memory ConcurrentHashMap.
 * PUT (`save()`) cache'i invalidate eder. `get()` cache'den okur, miss'te
 * DB'den yükler.
 *
 * <p>Multi-tenant: {@code companyCode} {@link CompanyContext}'ten alınır;
 * cache key {@code "<companyCode>:<channel>"}.
 *
 * <p>Sprint 29: plain text saklama. Sprint 30+: Jasypt encryption (`encrypted`
 * flag DB'de mevcut).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationConfigService {

    private final NotificationConfigRepository repo;
    private final Map<String, Map<String, String>> cache = new ConcurrentHashMap<>();

    @Value("${notification.config.security.warn:true}")
    private boolean securityWarn;

    /**
     * Channel'in tüm key-value config'i. Cache miss'te DB yükler.
     * Boş map dönerse channel için config yapılandırılmamış demektir
     * (fallback: application.properties).
     */
    public Map<String, String> get(NotificationChannel channel) {
        String cacheKey = cacheKey(channel);
        return cache.computeIfAbsent(cacheKey, k -> loadFromDb(channel));
    }

    /** Tek key okuma — convenience. */
    public Optional<String> get(NotificationChannel channel, String configKey) {
        return Optional.ofNullable(get(channel).get(configKey));
    }

    /**
     * Channel'in tüm config'ini upsert eder. Mevcut anahtarlar güncellenir,
     * yeni anahtarlar eklenir, gönderilmemiş anahtarlar **dokunulmaz**
     * (kısmi update — frontend password yeniden girmesin).
     */
    @Transactional
    public void save(NotificationChannel channel, Map<String, String> entries) {
        if (securityWarn && containsSensitive(channel, entries)) {
            log.warn("Notification config plain text saklanıyor (channel={}). "
                    + "Production için Jasypt/Vault entegrasyonu gerekli (Sprint 30+).",
                    channel);
        }
        for (var entry : entries.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            Optional<NotificationConfigEntity> existing =
                    repo.findByConfigChannelAndConfigKey(channel, key);
            if (existing.isPresent()) {
                NotificationConfigEntity ent = existing.get();
                ent.setConfigValue(value);
                repo.save(ent);
            } else {
                repo.save(NotificationConfigEntity.builder()
                        .configChannel(channel)
                        .configKey(key)
                        .configValue(value)
                        .encrypted(false)
                        .build());
            }
        }
        cache.remove(cacheKey(channel));
        log.info("Notification config kaydedildi: channel={}, keys={}",
                channel, entries.keySet());
    }

    /** Cache invalidate — admin/test için. */
    public void invalidateCache(NotificationChannel channel) {
        cache.remove(cacheKey(channel));
    }

    private Map<String, String> loadFromDb(NotificationChannel channel) {
        List<NotificationConfigEntity> entities = repo.findByConfigChannel(channel);
        Map<String, String> map = new HashMap<>();
        for (var e : entities) {
            // Sprint 30: encrypted=true ise jasypt.decrypt(e.configValue)
            map.put(e.getConfigKey(), e.getConfigValue());
        }
        return map;
    }

    private String cacheKey(NotificationChannel channel) {
        String company = CompanyContext.hasCompany() ? CompanyContext.get() : "_default";
        return company + ":" + channel.name();
    }

    private boolean containsSensitive(NotificationChannel channel, Map<String, String> entries) {
        // Sprint 29: kaba kontrol — password / token / secret içeren key'ler
        return entries.keySet().stream().anyMatch(k -> {
            String lk = k.toLowerCase();
            return lk.contains("password") || lk.contains("token") || lk.contains("secret");
        });
    }
}
