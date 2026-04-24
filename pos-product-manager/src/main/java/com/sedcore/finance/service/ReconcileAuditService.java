package com.sedcore.finance.service;

import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.finance.entity.ReconcileAuditLog;
import com.towpen.base.security.BaseDbService;

import java.math.BigDecimal;

public interface ReconcileAuditService extends BaseDbService<ReconcileAuditLog> {

    /**
     * Tek hesap reconcile sonucu için denetim kaydı yaz.
     * Drift yoksa da kayıt yazılır (correctionCount=0) — "ne zaman kontrol edildi" audit trail'i korunur.
     * Before/after aynıysa çağıran drift'in olmadığını bilir; after=null geçersen drift tespit edildi ama düzeltme yapılmadı anlamına gelir.
     */
    ReconcileAuditLog recordSingle(
            ReconcileEntityType entityType,
            String accountId,
            BigDecimal balanceBefore, BigDecimal balanceAfter,
            BigDecimal debtBefore, BigDecimal debtAfter,
            BigDecimal creditBefore, BigDecimal creditAfter,
            BigDecimal driftAmount);

    /**
     * Sweep reconcile özeti — reconcileAll sonunda toplam düzeltme sayısını kayıt altına alır.
     */
    ReconcileAuditLog recordSweep(ReconcileEntityType entityType, int correctionCount);
}
