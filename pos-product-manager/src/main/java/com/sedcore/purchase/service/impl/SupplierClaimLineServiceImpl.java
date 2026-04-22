package com.sedcore.purchase.service.impl;

import com.sedcore.purchase.entity.SupplierClaimLine;
import com.sedcore.purchase.model.SupplierClaimLineResponse;
import com.sedcore.purchase.repository.SupplierClaimLineRepository;
import com.sedcore.purchase.service.SupplierClaimLineService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class SupplierClaimLineServiceImpl
        extends BaseDbServiceImp<SupplierClaimLineRepository, SupplierClaimLine>
        implements SupplierClaimLineService {

    @Override
    public Class<?> getDTOClassForService() {
        return SupplierClaimLineResponse.class;
    }

    @Override
    public List<SupplierClaimLine> findByClaimId(String claimId) {
        return dao.findByClaimId(claimId);
    }

    @Override
    public List<SupplierClaimLine> findByClaimIdAndIsResolved(String claimId, Boolean isResolved) {
        return dao.findByClaimIdAndIsResolved(claimId, isResolved);
    }
}
