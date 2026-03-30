package com.sedcore.repository;

import com.sedcore.entity.Sale;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SaleRepository extends BaseDaoRepository<Sale> {

    Optional<Sale> findBySaleNumber(String saleNumber);

    List<Sale> findByCustomerId(String customerId);

    List<Sale> findByCustomerIdAndIsCancelledFalse(String customerId);
}
