package com.sedcore.repository;

import com.sedcore.entity.SaleReturnItem;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SaleReturnItemRepository extends BaseDaoRepository<SaleReturnItem> {

    List<SaleReturnItem> findBySaleReturnId(String saleReturnId);
}
