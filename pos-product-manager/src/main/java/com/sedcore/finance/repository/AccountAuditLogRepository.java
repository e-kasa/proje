package com.sedcore.finance.repository;

import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.finance.entity.AccountAuditLog;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AccountAuditLogRepository
        extends BaseDaoRepository<AccountAuditLog> {

    /** Tek bir entity için kronolojik (en yeni üstte) kayıt listesi. */
    List<AccountAuditLog> findByEntityTypeAndEntityIdOrderByCreateTimeDesc(
            AccountAuditEntityType entityType, String entityId);

    /** Sayfalı versiyon — büyük geçmişlerde kullanılır. */
    Page<AccountAuditLog> findByEntityTypeAndEntityIdOrderByCreateTimeDesc(
            AccountAuditEntityType entityType, String entityId, Pageable pageable);
}
