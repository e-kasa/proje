package com.sedcore.finance.repository;

import com.sedcore.common.enums.ReconcileEntityType;
import com.sedcore.common.enums.ReconcileScope;
import com.sedcore.finance.entity.ReconcileAuditLog;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReconcileAuditLogRepository extends BaseDaoRepository<ReconcileAuditLog> {

    List<ReconcileAuditLog> findByEntityTypeAndAccountIdOrderByCreateTimeDesc(
            ReconcileEntityType entityType, String accountId);

    Page<ReconcileAuditLog> findByEntityType(ReconcileEntityType entityType, Pageable pageable);

    Page<ReconcileAuditLog> findByScope(ReconcileScope scope, Pageable pageable);

    long countByScope(ReconcileScope scope);
}
