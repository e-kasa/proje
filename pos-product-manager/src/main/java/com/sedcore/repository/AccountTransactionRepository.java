package com.sedcore.repository;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.enums.TransactionType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AccountTransactionRepository extends BaseDaoRepository<AccountTransaction> {

    List<AccountTransaction> findBySupplierId(String supplierId);

    List<AccountTransaction> findBySupplierIdAndTransactionType(String supplierId, TransactionType type);

    List<AccountTransaction> findByPurchaseId(String purchaseId);

    List<AccountTransaction> findByCustomerId(String customerId);
}
