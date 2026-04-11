package com.sedcore.sales.repository;

import com.sedcore.sales.entity.SaleReturn;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SaleReturnRepository extends BaseDaoRepository<SaleReturn> {

    List<SaleReturn> findBySaleId(String saleId);
}
