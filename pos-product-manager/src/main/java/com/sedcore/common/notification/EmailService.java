package com.sedcore.common.notification;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import jakarta.annotation.Nullable;

/**
 * Minimal email sending service (Sprint 5 mini, 2026-04-24).
 *
 * Config (application.properties):
 *   mail.enabled=true|false           (default false — no-op)
 *   mail.from=noreply@sedcore.com
 *   spring.mail.host=smtp.example.com
 *   spring.mail.port=587
 *   spring.mail.username=...
 *   spring.mail.password=...          (env var: SPRING_MAIL_PASSWORD)
 *   spring.mail.properties.mail.smtp.auth=true
 *   spring.mail.properties.mail.smtp.starttls.enable=true
 *
 * mail.enabled=false veya JavaMailSender bean yok → sendWithAttachment(...) no-op
 * (log.warn ile atlanma nedeni) — dev'de hata atmaz, endpoint 503 yerine 200 + flag dönebilir.
 */
@Component
@Slf4j
public class EmailService {

    @Nullable
    private final JavaMailSender mailSender;
    private final boolean enabled;
    private final String fromAddress;

    public EmailService(
            @Nullable JavaMailSender mailSender,
            @Value("${mail.enabled:false}") boolean enabled,
            @Value("${mail.from:noreply@sedcore.com}") String fromAddress) {
        this.mailSender = mailSender;
        this.enabled = enabled;
        this.fromAddress = fromAddress;
    }

    public boolean isEnabled() {
        return enabled && mailSender != null;
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
            log.warn("Email gonderimi atlandi (mail.enabled=false veya JavaMailSender bean yok): to={}, subject={}",
                    to, subject);
            return false;
        }
        try {
            MimeMessage mime = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mime, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(bodyText, false);
            if (attachmentBytes != null && attachmentBytes.length > 0) {
                helper.addAttachment(attachmentFilename,
                        new org.springframework.core.io.ByteArrayResource(attachmentBytes));
            }
            mailSender.send(mime);
            log.info("Email gonderildi: to={}, subject={}, attachment={} byte",
                    to, subject, attachmentBytes != null ? attachmentBytes.length : 0);
            return true;
        } catch (Exception e) {
            log.error("Email gonderim hatasi: to={}, subject={}", to, subject, e);
            return false;
        }
    }
}
