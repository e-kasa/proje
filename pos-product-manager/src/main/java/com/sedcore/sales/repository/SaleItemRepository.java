package com.sedcore.sales.repository;

import com.sedcore.sales.entity.SaleItem;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SaleItemRepository extends BaseDaoRepository<SaleItem> {

    List<SaleItem> findBySaleId(String saleId);
}
