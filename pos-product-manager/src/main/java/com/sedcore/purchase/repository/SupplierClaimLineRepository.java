package com.sedcore.purchase.repository;

import com.sedcore.purchase.entity.SupplierClaimLine;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SupplierClaimLineRepository extends BaseDaoRepository<SupplierClaimLine> {

    List<SupplierClaimLine> findByClaimId(String claimId);

    List<SupplierClaimLine> findByClaimIdAndIsResolved(String claimId, Boolean isResolved);
}
