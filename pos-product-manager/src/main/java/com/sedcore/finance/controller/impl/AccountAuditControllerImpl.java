package com.sedcore.finance.controller.impl;

import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.finance.entity.AccountAuditLog;
import com.sedcore.finance.service.AccountAuditService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Sprint 30 — Cari hesap audit-log okuma endpoint'i (issue P2.6).
 *
 * <p>Frontend cari karta "Geçmiş" sekmesi açtığında {@code GET
 * /api/v1/audit/customer/{id}} ile çağrılır. Multi-tenant filter aktif —
 * yalnız çağıranın tenant'ı görülebilir.
 */
@RestController
@RequestMapping("api/v1/audit")
@RequiredArgsConstructor
@Slf4j
public class AccountAuditControllerImpl {

    private final AccountAuditService auditService;

    @GetMapping("/customer/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> customerHistory(
            @PathVariable String id) {
        return get(AccountAuditEntityType.CUSTOMER, id);
    }

    @GetMapping("/supplier/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> supplierHistory(
            @PathVariable String id) {
        return get(AccountAuditEntityType.SUPPLIER, id);
    }

    private ResponseEntity<ApiResponse<Map<String, Object>>> get(
            AccountAuditEntityType type, String id) {
        try {
            List<AccountAuditLog> logs = auditService.getHistory(type, id);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("entityType", type.name());
            result.put("entityId", id);
            result.put("count", logs.size());
            result.put("items", logs.stream().map(AccountAuditControllerImpl::toMap).toList());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Audit history hatası: type={}, id={}", type, id, e);
            throw ExceptionMapper.map(e);
        }
    }

    private static Map<String, Object> toMap(AccountAuditLog l) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", l.getId());
        m.put("createTime", l.getCreateTime());
        m.put("createUser", l.getCreateUser());
        m.put("action", l.getAction().name());
        m.put("fieldName", l.getFieldName());
        m.put("oldValue", l.getOldValue());
        m.put("newValue", l.getNewValue());
        m.put("reason", l.getReason());
        return m;
    }
}
