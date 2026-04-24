package com.sedcore.finance.service.impl;

import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.common.enums.ReconcileScope;
import com.sedcore.finance.entity.ReconcileAuditLog;
import com.sedcore.finance.repository.ReconcileAuditLogRepository;
import com.sedcore.finance.service.ReconcileAuditService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * Reconcile denetim kaydı servisi. Tek hesap reconcile + sweep özetleri için audit trail yazar.
 *
 * Not: {@link Propagation#REQUIRES_NEW} kullanılır — asıl reconcile transaction'ı rollback olsa bile
 * audit log korunsun (attempted-but-failed kayıtları da görünür). Eğer audit log da rollback olsa,
 * "kim ne zaman bunu denedi ama fail etti" bilgisini kaybederdik.
 */
@Service
@Slf4j
@Transactional(propagation = Propagation.REQUIRES_NEW)
public class ReconcileAuditServiceImpl
        extends BaseDbServiceImp<ReconcileAuditLogRepository, ReconcileAuditLog>
        implements ReconcileAuditService {

    @Override
    public Class<?> getDTOClassForService() {
        return ReconcileAuditLog.class;
    }

    @Override
    public ReconcileAuditLog recordSingle(
            ReconcileEntityType entityType,
            String accountId,
            BigDecimal balanceBefore, BigDecimal balanceAfter,
            BigDecimal debtBefore, BigDecimal debtAfter,
            BigDecimal creditBefore, BigDecimal creditAfter,
            BigDecimal driftAmount) {

        ReconcileAuditLog entry = ReconcileAuditLog.builder()
                .scope(ReconcileScope.SINGLE)
                .entityType(entityType)
                .accountId(accountId)
                .balanceBefore(balanceBefore)
                .balanceAfter(balanceAfter)
                .debtBefore(debtBefore)
                .debtAfter(debtAfter)
                .creditBefore(creditBefore)
                .creditAfter(creditAfter)
                .driftAmount(driftAmount)
                .correctionCount(driftAmount != null && driftAmount.compareTo(BigDecimal.ZERO) != 0 ? 1 : 0)
                .build();

        ReconcileAuditLog saved = save(entry);
        log.info("Reconcile audit [SINGLE] kaydedildi: entity={}, accountId={}, drift={}",
                entityType, accountId, driftAmount);
        return saved;
    }

    @Override
    public ReconcileAuditLog recordSweep(ReconcileEntityType entityType, int correctionCount) {
        ReconcileAuditLog entry = ReconcileAuditLog.builder()
                .scope(ReconcileScope.ALL)
                .entityType(entityType)
                .correctionCount(correctionCount)
                .build();

        ReconcileAuditLog saved = save(entry);
        log.info("Reconcile audit [ALL] kaydedildi: entity={}, corrected={}",
                entityType, correctionCount);
        return saved;
    }
}
