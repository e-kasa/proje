package com.sedcore.finance.controller.impl;

import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.supplier.service.SupplierAccountService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Admin Accounts Reconcile — denormalize currentBalance ile ledger (AccountTransaction)
 * arasındaki drift'i düzeltir. Manuel tetiklenir, scheduled job haline getirilmeden
 * önce operator tarafından doğrulanır.
 *
 * POST /product/api/v1/admin/accounts/reconcile            → customer + supplier hepsi
 * POST /product/api/v1/admin/accounts/reconcile/customer/{id}
 * POST /product/api/v1/admin/accounts/reconcile/supplier/{id}
 */
@RestController
@RequestMapping("api/v1/admin/accounts")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN')")
public class AdminAccountsReconcileControllerImpl {

    private final CustomerAccountService customerAccountService;
    private final SupplierAccountService supplierAccountService;

    @PostMapping("/reconcile")
    public ResponseEntity<ApiResponse<Map<String, Object>>> reconcileAll() {
        try {
            log.info("Admin reconcile baslatildi: customer + supplier");
            int customerCorrected = customerAccountService.reconcileAll();
            int supplierCorrected = supplierAccountService.reconcileAll();

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("customerCorrected", customerCorrected);
            result.put("supplierCorrected", supplierCorrected);
            result.put("totalCorrected", customerCorrected + supplierCorrected);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Admin reconcile hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/reconcile/customer/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> reconcileCustomer(@PathVariable String id) {
        try {
            BigDecimal drift = customerAccountService.reconcile(id);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("customerId", id);
            result.put("drift", drift);
            result.put("corrected", drift.compareTo(BigDecimal.ZERO) != 0);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Musteri reconcile hatasi: id={}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/reconcile/supplier/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> reconcileSupplier(@PathVariable String id) {
        try {
            BigDecimal drift = supplierAccountService.reconcile(id);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("supplierId", id);
            result.put("drift", drift);
            result.put("corrected", drift.compareTo(BigDecimal.ZERO) != 0);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Tedarikci reconcile hatasi: id={}", id, e);
            throw ExceptionMapper.map(e);
        }
    }
}
