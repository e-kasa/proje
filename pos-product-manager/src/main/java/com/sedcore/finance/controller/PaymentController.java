package com.sedcore.finance.controller;

import com.sedcore.finance.model.PaymentRequest;
import com.sedcore.finance.model.PaymentResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;

public interface PaymentController {

    ResponseEntity<ApiResponse<PaymentResponse>> create(PaymentRequest request);

    ResponseEntity<ApiResponse<PaymentResponse>> getById(String id);

    ResponseEntity<ApiResponse<List<PaymentResponse>>> listByCustomer(String customerId);

    ResponseEntity<ApiResponse<List<PaymentResponse>>> listBySupplier(String supplierId);

    ResponseEntity<ApiResponse<List<PaymentResponse>>> listBySale(String saleId);

    ResponseEntity<ApiResponse<List<PaymentResponse>>> listByPurchase(String purchaseId);

    ResponseEntity<ApiResponse<PaymentResponse>> cancel(String id, Map<String, String> body);

    ResponseEntity<ApiResponse<PaymentResponse>> verify(String id, Map<String, String> body);
}
