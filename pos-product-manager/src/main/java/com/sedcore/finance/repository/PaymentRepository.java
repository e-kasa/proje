package com.sedcore.finance.repository;

import com.sedcore.finance.entity.Payment;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaymentRepository extends BaseDaoRepository<Payment> {

    List<Payment> findBySupplierId(String supplierId);

    List<Payment> findByCustomerId(String customerId);

    List<Payment> findBySaleId(String saleId);

    List<Payment> findByPurchaseId(String purchaseId);

    List<Payment> findByIsVerified(Boolean isVerified);

    List<Payment> findByIsCancelled(Boolean isCancelled);
}
