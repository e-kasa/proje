package com.sedcore.purchase.repository;

import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.purchase.entity.SupplierClaim;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SupplierClaimRepository extends BaseDaoRepository<SupplierClaim> {

    List<SupplierClaim> findBySourcePurchaseId(String purchaseId);

    List<SupplierClaim> findBySupplierId(String supplierId);

    List<SupplierClaim> findBySupplierIdAndStatus(String supplierId, ClaimStatus status);

    List<SupplierClaim> findByStatus(ClaimStatus status);
}
