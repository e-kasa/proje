package com.sedcore.finance.controller.impl;

import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.finance.job.OverdueNotificationScheduledJob;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Sprint 30 — Vadesi geçen alacak bildirimi manuel tetikleme.
 *
 * <p>{@link OverdueNotificationScheduledJob} cron default {@code false}; ilk
 * hafta admin bu endpoint ile çalıştırır, davranış doğrulanınca cron açılır.
 *
 * <p>Tek tenant scope'unda çalışır — çağıran {@code X-Company-Code} header'ı
 * göndermeli (CompanyContextFilter set'ler). Multi-tenant batch için job'un
 * scheduled tetiklemesi kullanılır.
 */
@RestController
@RequestMapping("api/v1/admin/notifications")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN')")
public class AdminOverdueNotificationControllerImpl {

    private final OverdueNotificationScheduledJob job;

    @PostMapping("/overdue/scan")
    public ResponseEntity<ApiResponse<Map<String, Object>>> scanOverdue() {
        try {
            log.info("Admin overdue scan başlatıldı");
            OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("queued", r.queued());
            result.put("skipped", r.skipped());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Admin overdue scan hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
