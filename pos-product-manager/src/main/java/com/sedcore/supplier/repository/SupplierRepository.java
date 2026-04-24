package com.sedcore.supplier.repository;

import com.sedcore.common.enums.CustomerType;
import com.sedcore.supplier.entity.Supplier;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.stereotype.Repository;

@Repository
public interface SupplierRepository extends BaseDaoRepository<Supplier> {

    @EntityGraph(attributePaths = "account")
    Page<Supplier> findByIsActiveAndIsDeleted(Boolean isActive, Boolean isDeleted, Pageable pageable);

    @EntityGraph(attributePaths = "account")
    Page<Supplier> findByIsDeleted(Boolean isDeleted, Pageable pageable);

    // ─── AccountsHub stats (DB-side) ───────────────────────────────────────

    long countByIsDeleted(Boolean isDeleted);

    long countByIsActiveAndIsDeleted(Boolean isActive, Boolean isDeleted);

    long countByCustomerTypeAndIsDeleted(CustomerType type, Boolean isDeleted);
}
