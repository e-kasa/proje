package com.sedcore.service.impl;

import com.sedcore.entity.StockMovement;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.service.StockMovementService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class StockMovementServiceImpl
        extends BaseDbServiceImp<StockMovementRepository, StockMovement>
        implements StockMovementService {

    @Override
    public Class<?> getDTOClassForService() {
        return StockMovement.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<StockMovement> findByPurchaseId(String purchaseId) {
        return dao.findByPurchaseId(purchaseId);
    }

    @Override
    public StockMovement saveMovement(StockMovement movement) {
        return save(movement);
    }
}
