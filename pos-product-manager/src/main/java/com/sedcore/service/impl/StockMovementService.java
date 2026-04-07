package com.sedcore.service.impl;

// Bu sınıf StockMovementServiceImpl ile çakışıyor — @Service kaldırıldı.
// Gerçek implementasyon: StockMovementServiceImpl.java

import com.sedcore.entity.StockMovement;
import com.towpen.base.security.BaseDbServiceImp;

import java.util.List;

public class StockMovementService extends BaseDbServiceImp<StokMovementRepository,StockMovement> implements com.sedcore.service.StockMovementService {

    @Override
    public Class<?> getDTOClassForService() {
        return StockMovement.class;
    }

    @Override
    public List<StockMovement> findByPurchaseId(String purchaseId) {
        return List.of();
    }

    @Override
    public StockMovement saveMovement(StockMovement movement) {
        return null;
    }
}
