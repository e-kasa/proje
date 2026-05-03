package com.sedcore.common.notification;

import com.sedcore.notification.config.service.NotificationConfigService;
import com.sedcore.notification.entity.NotificationChannel;
import jakarta.annotation.Nullable;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Properties;

/**
 * Minimal email sending service (Sprint 5 mini, 2026-04-24 → Sprint 29 refactor).
 *
 * <p>Sprint 29 refactor — DB-stored config (Sprint 29 NotificationConfigService)
 * öncelikli; yoksa application.properties fallback (Sprint 5 davranışı).
 *
 * <p>Config kaynağı önceliği:
 * <ol>
 *   <li>{@code NotificationConfigService.get(EMAIL)} — UI'dan kaydedilmiş
 *       multi-tenant config (host, port, useTls, username, password, from, enabled)
 *   <li>application.properties — {@code mail.enabled}, {@code mail.from},
 *       {@code spring.mail.*} (Spring autoconfigure JavaMailSender bean)
 * </ol>
 *
 * <p>DB'de yapılandırılmış şirketler için her {@code sendWithAttachment} çağrısı
 * yeni bir {@link JavaMailSenderImpl} oluşturur (config refresh garantisi).
 * Yapılandırılmamış şirketler eski autowired bean'ı kullanır (sıfır overhead).
 *
 * <p>Sprint 30+: Jasypt encryption (password decrypt-on-read), HTML body,
 * template engine.
 */
@Component
@Slf4j
public class EmailService {

    @Nullable
    private final JavaMailSender autowiredMailSender;
    private final boolean defaultEnabled;
    private final String defaultFromAddress;
    private final NotificationConfigService configService;

    public EmailService(
            @Nullable JavaMailSender mailSender,
            @Value("${mail.enabled:false}") boolean enabled,
            @Value("${mail.from:noreply@sedcore.com}") String fromAddress,
            NotificationConfigService configService) {
        this.autowiredMailSender = mailSender;
        this.defaultEnabled = enabled;
        this.defaultFromAddress = fromAddress;
        this.configService = configService;
    }

    /**
     * Email gönderim aktif mi? DB config öncelikli; yoksa property + autowired
     * JavaMailSender mevcudiyetine düşer.
     */
    public boolean isEnabled() {
        Map<String, String> dbConfig = configService.get(NotificationChannel.EMAIL);
        if (!dbConfig.isEmpty()) {
            // DB enabled flag'i varsa kullan; yoksa host doluysa true varsay
            String enabledStr = dbConfig.get("enabled");
            if (enabledStr != null) return Boolean.parseBoolean(enabledStr);
            return dbConfig.get("host") != null && !dbConfig.get("host").isBlank();
        }
        return defaultEnabled && autowiredMailSender != null;
    }

    /**
     * PDF attachment ile email gönder.
     *
     * @return true başarıyla gönderildi, false no-op / hata
     */
    public boolean sendWithAttachment(
            String to, String subject, String bodyText,
            String attachmentFilename, byte[] attachmentBytes) {
        if (!isEnabled()) {
            log.warn("Email gonderimi atlandi (config eksik): to={}, subject={}", to, subject);
            return false;
        }
        Map<String, String> dbConfig = configService.get(NotificationChannel.EMAIL);
        JavaMailSender sender = resolveSender(dbConfig);
        if (sender == null) {
            log.warn("JavaMailSender oluşturulamadı (config geçersiz): to={}", to);
            return false;
        }
        String fromAddress = dbConfig.getOrDefault("from", defaultFromAddress);
        try {
            MimeMessage mime = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mime, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(bodyText, false);
            if (attachmentBytes != null && attachmentBytes.length > 0) {
                helper.addAttachment(attachmentFilename,
                        new org.springframework.core.io.ByteArrayResource(attachmentBytes));
            }
            sender.send(mime);
            log.info("Email gonderildi: to={}, subject={}, attachment={} byte, source={}",
                    to, subject,
                    attachmentBytes != null ? attachmentBytes.length : 0,
                    dbConfig.isEmpty() ? "properties" : "db-config");
            return true;
        } catch (Exception e) {
            log.error("Email gonderim hatasi: to={}, subject={}", to, subject, e);
            return false;
        }
    }

    /**
     * DB config doluysa yeni JavaMailSenderImpl oluştur; aksi halde autowired
     * Spring bean'i (application.properties tabanlı) kullan.
     */
    @Nullable
    private JavaMailSender resolveSender(Map<String, String> dbConfig) {
        String host = dbConfig.get("host");
        if (host == null || host.isBlank()) {
            return autowiredMailSender;  // fallback Sprint 5 davranışı
        }
        JavaMailSenderImpl impl = new JavaMailSenderImpl();
        impl.setHost(host);
        try {
            String portStr = dbConfig.get("port");
            if (portStr != null && !portStr.isBlank()) {
                impl.setPort(Integer.parseInt(portStr.trim()));
            }
        } catch (NumberFormatException e) {
            log.warn("Geçersiz port DB config'inde: {}", dbConfig.get("port"));
        }
        impl.setUsername(dbConfig.get("username"));
        impl.setPassword(dbConfig.get("password"));
        Properties props = impl.getJavaMailProperties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.auth", "true");
        boolean useTls = Boolean.parseBoolean(dbConfig.getOrDefault("useTls", "true"));
        props.put("mail.smtp.starttls.enable", String.valueOf(useTls));
        return impl;
    }
}
