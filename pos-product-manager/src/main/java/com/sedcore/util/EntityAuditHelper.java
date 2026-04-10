package com.sedcore.util;

import com.sedcore.context.CompanyContext;
import com.towpen.base.context.TOpenContextHolder;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.security.ISessionInstanceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Calendar;

/**
 * Tüm entity save işlemleri için merkezi audit alanı doldurma yardımcısı.
 *
 * BaseDbServiceImp.save() bu alanları otomatik set eder.
 * Ancak bazı controller'lar repository.save() ile doğrudan kayıt yaptığında
 * bu mekanizma devre dışı kalır ve company_code / create_user NULL olur.
 *
 * Kullanım:
 *   entityAuditHelper.prepare(entity);
 *   repository.save(entity);
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class EntityAuditHelper {

    private final ISessionInstanceService sessionInstanceService;

    /**
     * Entity kayıt öncesi audit alanlarını doldurur.
     * - companyCode  : CompanyContext → TOpenContextHolder → "SYSTEM"
     * - createUser   : ISessionInstanceService → "SYSTEM"
     * - createTime   : Calendar.now() (sadece null ise)
     */
    public void prepare(TOpenSimpleCompanyEntity entity) {
        // ── Company Code ──────────────────────────────────────────────────────
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) {
            String cc = resolveCompanyCode();
            entity.setCompanyCode(cc);
        }

        // ── Create Time ───────────────────────────────────────────────────────
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(Calendar.getInstance().getTime());
        }

        // ── Create User ───────────────────────────────────────────────────────
        if (entity.getCreateUser() == null || entity.getCreateUser().isBlank()) {
            String user = resolveUserCode();
            entity.setCreateUser(user);
        }
    }

    // ── Özel yardımcılar ──────────────────────────────────────────────────────

    private String resolveCompanyCode() {
        // 1. CompanyContext (JWT filter tarafından set edilir)
        String cc = CompanyContext.get();
        if (cc != null && !cc.isBlank()) return cc;

        // 2. TOpenContextHolder (towpen framework context)
        try {
            var ctx = TOpenContextHolder.getContext();
            if (ctx != null && ctx.getCompanyCode() != null && !ctx.getCompanyCode().isBlank()) {
                return ctx.getCompanyCode();
            }
        } catch (Exception ignored) { }

        // 3. sessionInstanceService
        try {
            String fromSession = sessionInstanceService.getSelectedCompanyCode();
            if (fromSession != null && !fromSession.isBlank()) return fromSession;
        } catch (Exception ignored) { }

        log.warn("EntityAuditHelper: company code cozumlenemedi, 'syste' kullaniliyor");
        return "SYSTEM";
    }

    private String resolveUserCode() {
        try {
            String user = sessionInstanceService.getUserCode();
            if (user != null && !user.isBlank()) return user;
        } catch (Exception ignored) { }
        return "SYSTEM";
    }
}
