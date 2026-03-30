package com.sedcore.service;

import com.sedcore.entity.StockMovement;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface StockMovementService extends BaseDbService<StockMovement> {

    /** Purchase'a ait tüm stok hareketleri */
    List<StockMovement> findByPurchaseId(String purchaseId);

    /** Stok hareketi kaydet */
    StockMovement saveMovement(StockMovement movement);
}
