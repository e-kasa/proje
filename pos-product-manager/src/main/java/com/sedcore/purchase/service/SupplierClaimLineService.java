package com.sedcore.purchase.service;

import com.sedcore.purchase.entity.SupplierClaimLine;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface SupplierClaimLineService extends BaseDbService<SupplierClaimLine> {

    List<SupplierClaimLine> findByClaimId(String claimId);

    List<SupplierClaimLine> findByClaimIdAndIsResolved(String claimId, Boolean isResolved);
}
