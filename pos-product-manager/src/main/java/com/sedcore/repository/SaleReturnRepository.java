package com.sedcore.repository;

import com.sedcore.entity.SaleReturn;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SaleReturnRepository extends BaseDaoRepository<SaleReturn> {

    List<SaleReturn> findBySaleId(String saleId);
}
