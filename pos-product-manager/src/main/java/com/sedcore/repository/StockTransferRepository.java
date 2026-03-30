package com.sedcore.repository;

import com.sedcore.entity.StockTransfer;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StockTransferRepository extends BaseDaoRepository<StockTransfer> {

    List<StockTransfer> findByFromStoreId(String fromStoreId);

    List<StockTransfer> findByToStoreId(String toStoreId);
}
