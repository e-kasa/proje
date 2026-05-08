package com.sedcore.finance.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.enums.AccountAuditAction;
import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.finance.entity.AccountAuditLog;
import com.sedcore.finance.repository.AccountAuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Objects;

/**
 * Sprint 30 — AccountAuditLog yazıcı/okuyucu servis (issue P2.6).
 *
 * <p>Entity-level değişiklikleri kayıt altına alır. Servis çağırıcı (ör.
 * {@code CustomerServiceImpl.updateCreditLimit}) eski değer + yeni değer ile
 * {@link #recordFieldChange} çağırır.
 *
 * <p>Eski/yeni değer aynıysa kayıt yazılmaz — log spam'i önler.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AccountAuditService {

    private final AccountAuditLogRepository repo;

    /** Tek alan değişikliği — eski/yeni eşitse no-op. */
    @Transactional
    public void recordFieldChange(AccountAuditEntityType type,
                                  String entityId,
                                  String fieldName,
                                  Object oldValue,
                                  Object newValue,
                                  String reason) {
        if (entityId == null || fieldName == null) return;
        String oldStr = stringify(oldValue);
        String newStr = stringify(newValue);
        if (Objects.equals(oldStr, newStr)) return;
        persist(AccountAuditLog.builder()
                .entityType(type)
                .entityId(entityId)
                .action(AccountAuditAction.UPDATE)
                .fieldName(fieldName)
                .oldValue(oldStr)
                .newValue(newStr)
                .reason(reason)
                .build());
    }

    /** Birden çok alanı tek loop'ta — null/eşit olanlar atlanır. */
    @Transactional
    public void recordFieldChanges(AccountAuditEntityType type,
                                   String entityId,
                                   List<FieldChange> changes,
                                   String reason) {
        if (changes == null) return;
        for (FieldChange c : changes) {
            recordFieldChange(type, entityId, c.field(), c.oldValue(),
                    c.newValue(), reason);
        }
    }

    /** Yeni entity — tek satır CREATE kaydı (alanlar boş). */
    @Transactional
    public void recordCreate(AccountAuditEntityType type, String entityId,
                             String reason) {
        if (entityId == null) return;
        persist(AccountAuditLog.builder()
                .entityType(type)
                .entityId(entityId)
                .action(AccountAuditAction.CREATE)
                .reason(reason)
                .build());
    }

    /** Soft/hard delete — tek satır. */
    @Transactional
    public void recordDelete(AccountAuditEntityType type, String entityId,
                             String reason) {
        if (entityId == null) return;
        persist(AccountAuditLog.builder()
                .entityType(type)
                .entityId(entityId)
                .action(AccountAuditAction.DELETE)
                .reason(reason)
                .build());
    }

    /**
     * BaseDbServiceImp dışında JpaRepository üzerinden direkt save yapıldığı için
     * {@code prepareForInsert} hook'u devreye girmez — multi-tenant + audit
     * kolonlarını burada elle setleriz.
     */
    private void persist(AccountAuditLog log) {
        if (log.getCompanyCode() == null) {
            log.setCompanyCode(CompanyContext.hasCompany()
                    ? CompanyContext.get() : "_default");
        }
        if (log.getCreateUser() == null) {
            log.setCreateUser(currentUsername());
        }
        if (log.getCreateTime() == null) {
            log.setCreateTime(Calendar.getInstance().getTime());
        }
        repo.save(log);
    }

    private static String currentUsername() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null && !auth.getName().isBlank()) {
            return auth.getName();
        }
        return "SYSTEM";
    }

    @Transactional(readOnly = true)
    public List<AccountAuditLog> getHistory(AccountAuditEntityType type,
                                            String entityId) {
        return repo.findByEntityTypeAndEntityIdOrderByCreateTimeDesc(type, entityId);
    }

    @Transactional(readOnly = true)
    public Page<AccountAuditLog> getHistory(AccountAuditEntityType type,
                                            String entityId,
                                            Pageable pageable) {
        return repo.findByEntityTypeAndEntityIdOrderByCreateTimeDesc(
                type, entityId, pageable);
    }

    private static String stringify(Object value) {
        if (value == null) return null;
        String s = value.toString();
        if (s.length() > 1024) {
            log.warn("Audit value 1024 karakteri aştı, kısaltıldı: field-len={}",
                    s.length());
            return s.substring(0, 1024);
        }
        return s;
    }

    /** Çoklu alan değişikliği için yardımcı kayıt — tip-güvenli builder. */
    public record FieldChange(String field, Object oldValue, Object newValue) {
        public static FieldChange of(String field, Object oldValue, Object newValue) {
            return new FieldChange(field, oldValue, newValue);
        }
    }

    /** Convenience — listeye tek tek change ekleyici. */
    public static List<FieldChange> changeList() {
        return new ArrayList<>();
    }
}
