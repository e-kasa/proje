package com.sedcore.finance.job;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.notification.SlackNotifier;
import com.sedcore.company.repository.CompanySettingRepository;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.repository.CustomerAccountRepository;
import com.sedcore.notification.dto.NotificationRequestDto;
import com.sedcore.notification.entity.NotificationChannel;
import com.sedcore.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;

/**
 * Sprint 30 — Vadesi geçen alacak bildirimi (issue P2.4 çözümü).
 *
 * <p>{@link ReconcileScheduledJob} paterni paralel — multi-tenant loop +
 * feature flag + Slack özet. Her gün belirlenen saatte (default 09:00) tüm
 * aktif tenant'ların {@code overdueAmount > 0} müşterilerine iletişim
 * kanalına göre EMAIL veya SMS bildirim queue'lar.
 *
 * <p>Kanal seçimi: müşteri email varsa EMAIL, yoksa phone varsa SMS, ikisi
 * de yoksa atla (repository sorgusu zaten filtrele). EMAIL preferred (maliyet
 * + içerik daha zengin); Twilio SMS pahalı, fallback rolü.
 *
 * <p>Bildirim {@link NotificationService#queue(NotificationRequestDto)}
 * üzerinden geçer — sync persist + async dispatch + retry. Job kendisi
 * gönderim yapmaz, sadece kuyruğa atar.
 *
 * <p>Feature flag: {@code overdue.notification.enabled} default {@code false}
 * (prod safe rollout). İlk hafta manuel admin endpoint ile tetiklenebilir,
 * davranış doğrulanınca cron açılır.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class OverdueNotificationScheduledJob {

    private final CustomerAccountRepository customerAccountRepository;
    private final CompanySettingRepository companySettingRepository;
    private final NotificationService notificationService;
    private final SlackNotifier slackNotifier;

    @Value("${overdue.notification.enabled:false}")
    private boolean enabled;

    /**
     * Pazartesi-Cuma 09:00. Hafta sonu mesai dışı; spam riski azaltır.
     * Cron format: saniye dakika saat DoM ay DoW.
     */
    @Scheduled(cron = "${overdue.notification.cron:0 0 9 * * MON-FRI}")
    public void dailyOverdueScan() {
        if (!enabled) {
            log.debug("Overdue notification atlandı (overdue.notification.enabled=false)");
            return;
        }

        long start = System.currentTimeMillis();

        List<String> companyCodes;
        try {
            companyCodes = companySettingRepository.findAllActiveCompanyCodes();
        } catch (Exception e) {
            String err = e.getClass().getSimpleName() + ": " + e.getMessage();
            log.error("Overdue scan tenant listesi alınamadı: {}", err, e);
            slackNotifier.notify(":x: POS Overdue — tenant listesi alınamadı: " + err);
            return;
        }

        if (companyCodes == null || companyCodes.isEmpty()) {
            log.warn("Overdue scan: tenant bulunamadı");
            return;
        }

        int tenantsProcessed = 0;
        int tenantsFailed = 0;
        int totalQueued = 0;
        int totalSkipped = 0;
        StringBuilder failures = new StringBuilder();

        log.info("Overdue scan başladı: tenant sayısı={}", companyCodes.size());

        for (String companyCode : companyCodes) {
            if (companyCode == null || companyCode.isBlank()) continue;
            try {
                CompanyContext.set(companyCode);
                ScanResult r = scanTenant();
                totalQueued += r.queued;
                totalSkipped += r.skipped;
                tenantsProcessed++;
                log.info("Overdue scan tenant OK: {} — queued={}, skipped={}",
                        companyCode, r.queued, r.skipped);
            } catch (Exception e) {
                tenantsFailed++;
                String err = e.getClass().getSimpleName() + ": " + e.getMessage();
                log.error("Overdue scan tenant HATA: {} — {}", companyCode, err, e);
                if (failures.length() > 0) failures.append("; ");
                failures.append(companyCode).append("=").append(err);
            } finally {
                CompanyContext.clear();
            }
        }

        long durationMs = System.currentTimeMillis() - start;
        log.info("Overdue scan tamamlandı: tenant OK={}, fail={}, queued={}, skipped={}, süre={}ms",
                tenantsProcessed, tenantsFailed, totalQueued, totalSkipped, durationMs);

        if (totalQueued > 0 || tenantsFailed > 0) {
            String msg = String.format(
                    ":bell: POS Overdue (daily) — tenant OK=%d/%d, queued=%d, skipped=%d, süre=%dms%s",
                    tenantsProcessed, companyCodes.size(),
                    totalQueued, totalSkipped, durationMs,
                    tenantsFailed > 0 ? ", HATALAR: " + failures : "");
            slackNotifier.notify(msg);
        }
    }

    /** Test/admin için tek-tenant tetikleme. CompanyContext set'lenmiş olmalı. */
    public ScanResult scanTenant() {
        List<CustomerAccount> overdue = customerAccountRepository.findOverdueWithContact();
        if (overdue.isEmpty()) {
            return new ScanResult(0, 0);
        }
        int queued = 0;
        int skipped = 0;
        for (CustomerAccount a : overdue) {
            try {
                if (queueOne(a)) {
                    queued++;
                } else {
                    skipped++;
                }
            } catch (Exception e) {
                skipped++;
                log.warn("Overdue notification queue hatası: customerId={}, err={}",
                        a.getCustomer() != null ? a.getCustomer().getId() : "?",
                        e.getMessage());
            }
        }
        return new ScanResult(queued, skipped);
    }

    private boolean queueOne(CustomerAccount account) {
        Customer c = account.getCustomer();
        if (c == null) return false;

        String email = trimToNull(c.getEmail());
        String phone = trimToNull(c.getPhone());
        if (email == null && phone == null) return false;

        BigDecimal overdueAmount = account.getOverdueAmount();
        BigDecimal currentBalance = account.getCurrentBalance();

        // EMAIL preferred — daha zengin içerik + düşük maliyet
        if (email != null) {
            notificationService.queue(NotificationRequestDto.builder()
                    .eventType("ACCOUNT_OVERDUE")
                    .channel(NotificationChannel.EMAIL)
                    .recipient(email)
                    .subject(buildSubject(c.getName()))
                    .body(buildEmailBody(c.getName(), overdueAmount, currentBalance))
                    .build());
            return true;
        }

        // SMS fallback — kısa ve net
        notificationService.queue(NotificationRequestDto.builder()
                .eventType("ACCOUNT_OVERDUE")
                .channel(NotificationChannel.SMS)
                .recipient(phone)
                .body(buildSmsBody(c.getName(), overdueAmount))
                .build());
        return true;
    }

    private static String trimToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private static String buildSubject(String customerName) {
        return "[SEDCORE] Vadesi geçen bakiye hatırlatması — " + customerName;
    }

    private static String buildEmailBody(String name, BigDecimal overdue, BigDecimal balance) {
        NumberFormat money = NumberFormat.getCurrencyInstance(new Locale("tr", "TR"));
        return String.format(
                "Sayın %s,%n%n"
                        + "Cari hesabınızda vadesi geçen bir bakiye bulunmaktadır:%n%n"
                        + "  Vadesi geçen tutar : %s%n"
                        + "  Güncel bakiye      : %s%n%n"
                        + "Ödemenizi en kısa sürede yapmanızı rica ederiz. Sorularınız "
                        + "için bizimle iletişime geçebilirsiniz.%n%n"
                        + "İyi günler dileriz.%nSEDCORE POS",
                name,
                money.format(overdue == null ? BigDecimal.ZERO : overdue),
                money.format(balance == null ? BigDecimal.ZERO : balance));
    }

    private static String buildSmsBody(String name, BigDecimal overdue) {
        NumberFormat money = NumberFormat.getCurrencyInstance(new Locale("tr", "TR"));
        return String.format(
                "Sayin %s, vadesi gecen bakiyeniz: %s. Odeme icin lutfen iletisime gecin. - SEDCORE",
                name,
                money.format(overdue == null ? BigDecimal.ZERO : overdue));
    }

    /** Job çıktısı — admin endpoint manuel tetikleme dönüş tipi. */
    public record ScanResult(int queued, int skipped) {}
}
