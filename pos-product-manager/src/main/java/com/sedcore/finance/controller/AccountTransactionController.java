package com.sedcore.finance.controller;

import com.sedcore.common.enums.TransactionType;
import com.sedcore.finance.model.AccountTransactionResponse;

import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;

public interface AccountTransactionController {

    ResponseEntity<ApiResponse<AccountTransactionResponse>> getById(String id);

    ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listBySupplier(String supplierId, TransactionType type);

    ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listByCustomer(String customerId);

    ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listByPurchase(String purchaseId);

    ResponseEntity<ApiResponse<AccountTransactionResponse>> cancel(String id, Map<String, String> body);
}
