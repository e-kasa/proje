package com.sedcore.repository;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.enums.TransactionType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AccountTransactionRepository extends BaseDaoRepository<AccountTransaction> {

    List<AccountTransaction> findBySupplierId(String supplierId);

    List<AccountTransaction> findBySupplierIdAndTransactionType(String supplierId, TransactionType type);

    List<AccountTransaction> findByPurchaseId(String purchaseId);

    List<AccountTransaction> findByCustomerId(String customerId);

    // Satış bazlı hareketler (iptal sırasında orijinal SALE tx'i bulmak için)
    @Query("SELECT t FROM AccountTransaction t WHERE t.sale.id = :saleId")
    List<AccountTransaction> findBySaleId(@Param("saleId") String saleId);
}
