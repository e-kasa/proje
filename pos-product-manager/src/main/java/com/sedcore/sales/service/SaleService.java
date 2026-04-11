package com.sedcore.sales.service;

import com.sedcore.sales.entity.Sale;
import com.towpen.base.security.BaseDbService;

import java.util.List;
import java.util.Optional;

public interface SaleService extends BaseDbService<Sale> {

    /** Entity olarak satışı getir — diğer servislerde entity build işlemleri için */
    Sale getEntity(String id);

    List<Sale> findByCustomerId(String customerId);

    Optional<Sale> findBySaleNumber(String saleNumber);
}
