package com.sedcore.notification.config.controller;

import com.sedcore.notification.config.dto.EmailConfigDto;
import com.sedcore.notification.config.service.NotificationConfigService;
import com.sedcore.notification.entity.NotificationChannel;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Sprint 29 — Notification channel-specific config save endpoint'leri.
 *
 * <p>EMAIL: GET/PUT /api/v1/notification-settings/email<br>
 * SMS: Sprint 30+ ekleme.
 *
 * <p>Multi-tenant: {@code X-Company-Code} header'ı CompanyContextFilter
 * tarafından ThreadLocal'a yazılır; service entity persist ederken
 * {@code TOpenSimpleCompanyEntity} otomatik {@code companyCode} ekler.
 */
@RestController
@RequestMapping("/api/v1/notification-settings")
@RequiredArgsConstructor
@Tag(name = "Notification Settings",
        description = "SMTP/Twilio/SendGrid config save (Sprint 29+)")
public class NotificationConfigController {

    private static final String MASKED = "****";

    // Email config keys (NotificationConfigService key-value tablosunda saklanır)
    private static final String K_HOST = "host";
    private static final String K_PORT = "port";
    private static final String K_USE_TLS = "useTls";
    private static final String K_USERNAME = "username";
    private static final String K_PASSWORD = "password";
    private static final String K_FROM = "from";
    private static final String K_ENABLED = "enabled";

    private final NotificationConfigService configService;

    // Backward compat: mevcut application.properties fallback'ı
    @Value("${mail.from:noreply@sedcore.com}") String defaultFrom;
    @Value("${mail.enabled:false}") boolean defaultEnabled;

    @Operation(summary = "Mevcut email config (password maskelenmiş)")
    @GetMapping("/email")
    public ResponseEntity<EmailConfigDto> getEmailConfig() {
        Map<String, String> stored = configService.get(NotificationChannel.EMAIL);
        EmailConfigDto dto = EmailConfigDto.builder()
                .channel("EMAIL")
                .host(stored.get(K_HOST))
                .port(parseInt(stored.get(K_PORT)))
                .useTls(parseBool(stored.get(K_USE_TLS)))
                .username(stored.get(K_USERNAME))
                // Password mask — gerçek değer asla cliente gönderilmez
                .password(stored.containsKey(K_PASSWORD) ? MASKED : null)
                .from(stored.getOrDefault(K_FROM, defaultFrom))
                .enabled(parseBool(stored.get(K_ENABLED)) != null
                        ? parseBool(stored.get(K_ENABLED))
                        : defaultEnabled)
                .build();
        return ResponseEntity.ok(dto);
    }

    @Operation(
            summary = "Email config kaydet (kısmi update)",
            description = "Password null/boş ise mevcut password korunur. "
                    + "Diğer alanlar dolduruldukça güncellenir."
    )
    @PutMapping("/email")
    public ResponseEntity<EmailConfigDto> saveEmailConfig(
            @RequestBody @Valid EmailConfigDto req) {
        Map<String, String> entries = new HashMap<>();
        if (req.getHost() != null) entries.put(K_HOST, req.getHost());
        if (req.getPort() != null) entries.put(K_PORT, String.valueOf(req.getPort()));
        if (req.getUseTls() != null) entries.put(K_USE_TLS, String.valueOf(req.getUseTls()));
        if (req.getUsername() != null) entries.put(K_USERNAME, req.getUsername());
        // Password sadece dolu ve mask değilse güncelle
        if (req.getPassword() != null
                && !req.getPassword().isBlank()
                && !MASKED.equals(req.getPassword())) {
            entries.put(K_PASSWORD, req.getPassword());
        }
        if (req.getFrom() != null) entries.put(K_FROM, req.getFrom());
        if (req.getEnabled() != null) entries.put(K_ENABLED, String.valueOf(req.getEnabled()));

        configService.save(NotificationChannel.EMAIL, entries);

        // Yeni durumu döndür (GET ile aynı format)
        return getEmailConfig();
    }

    private static Integer parseInt(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Boolean parseBool(String s) {
        if (s == null || s.isBlank()) return null;
        return "true".equalsIgnoreCase(s.trim());
    }
}
