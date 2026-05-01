package com.sedcore.notification.controller;

import com.sedcore.notification.dto.NotificationDto;
import com.sedcore.notification.dto.NotificationRequestDto;
import com.sedcore.notification.entity.NotificationStatus;
import com.sedcore.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Sprint 25 — POST /api/v1/notifications/send + GET /api/v1/notifications.
 *
 * <p>Akış: HTTP request → {@code service.queue()} (PENDING persist) → 202
 * Accepted ile DTO döner → arka plan @Async deliver çalışır.
 *
 * <p>Multi-tenant: {@code X-Company-Code} header'ı CompanyContextFilter
 * tarafından ThreadLocal'a yazılır; service entity persist ederken
 * {@code TOpenSimpleCompanyEntity} otomatik {@code companyCode} ekler.
 */
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications", description = "SMS / Email / WhatsApp bildirim API'si (Sprint 25+)")
public class NotificationController {

    private final NotificationService service;

    @Operation(
            summary = "Bildirim kuyruğa al",
            description = "Notification entity persist edilir (PENDING), arka plan async dispatch tetiklenir. "
                    + "Sprint 25'te EMAIL kanalı real, diğer kanallar UnsupportedChannelException → status=FAILED."
    )
    @PostMapping("/send")
    public ResponseEntity<NotificationDto> send(@RequestBody @Valid NotificationRequestDto req) {
        NotificationDto dto = service.queue(req);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(dto);
    }

    @Operation(
            summary = "Bildirim listesi (admin/audit)",
            description = "En yeni üste sıralı. status filtresi opsiyonel "
                    + "(PENDING / RETRYING / SENT / FAILED)."
    )
    @GetMapping
    public Page<NotificationDto> list(
            @Parameter(description = "Filtre: PENDING | RETRYING | SENT | FAILED")
            @RequestParam(required = false) NotificationStatus status,
            Pageable pageable) {
        return service.list(status, pageable);
    }
}
