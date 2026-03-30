package com.sedcore.service;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.AccountTransactionResponse;
import com.towpen.base.security.BaseDbService;
import org.springframework.beans.PropertyValues;

import java.util.List;

public interface AccountTransactionService extends BaseDbService<AccountTransaction> {

    AccountTransactionResponse getTransaction(String id);

    List<AccountTransactionResponse> getBySupplier(String supplierId);

    List<AccountTransactionResponse> getBySupplierAndType(String supplierId, TransactionType type);

    List<AccountTransactionResponse> getByCustomer(String customerId);

    List<AccountTransactionResponse> getByPurchase(String purchaseId);

    AccountTransactionResponse cancelTransaction(String id, String reason);

    List<AccountTransactionResponse> findBySupplierId(String supplierId);
}
