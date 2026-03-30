package com.sedcore.service;

import com.sedcore.entity.Sale;
import com.towpen.base.security.BaseDbService;

public interface SaleService extends BaseDbService<Sale> {

    /** Entity olarak satışı getir — diğer servislerde entity build işlemleri için */
    Sale getEntity(String id);
}
