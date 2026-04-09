package com.sedcore.controller.impl;

import com.sedcore.entity.Supplier;
import com.sedcore.model.AccountTransactionResponse;
import com.sedcore.model.SupplierAccountResponse;
import com.sedcore.model.SupplierDto;
import com.sedcore.model.SupplierPaymentDto;
import com.sedcore.model.SupplierResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.SupplierService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/suppliers")
@RequiredArgsConstructor
@Slf4j
public class SupplierControllerImpl {

    private final SupplierService supplierService;

    // GET /product/api/v1/suppliers?search=...&isActive=true
    @GetMapping
    public ResponseEntity<ApiResponse<List<SupplierResponse>>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "200") int size
    ) {
        try {
            // Sayfalı liste al, sonra search filtresi uygula
            var pageResult = supplierService.listSuppliers(PageRequest.of(page, size), isActive);
            final String q = search != null ? search.toLowerCase() : null;
            List<SupplierResponse> filtered = pageResult.stream()
                .filter(s -> q == null
                    || (s.getName() != null && s.getName().toLowerCase().contains(q))
                    || (s.getContactName() != null && s.getContactName().toLowerCase().contains(q))
                    || (s.getPhone() != null && s.getPhone().contains(q))
                    || (s.getEmail() != null && s.getEmail().toLowerCase().contains(q)))
                .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(filtered));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Tedarikci listesi hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/suppliers/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SupplierResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.getSupplier(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/v1/suppliers
    @PostMapping
    public ResponseEntity<ApiResponse<SupplierResponse>> create(@Valid @RequestBody SupplierDto dto) {
        try {
            Supplier saved = supplierService.createSupplier(dto);
            log.info("Tedarikci olusturuldu: {}", saved.getName());
            return ResponseEntity.ok(ApiResponse.success(supplierService.getSupplier(saved.getId())));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Tedarikci olusturma hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PUT /product/api/v1/suppliers/{id}
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<SupplierResponse>> update(
            @PathVariable String id,
            @RequestBody SupplierDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.updateSupplier(id, dto)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // DELETE /product/api/v1/suppliers/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable String id) {
        try {
            supplierService.deleteSupplier(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PATCH /product/api/v1/suppliers/{id}/toggle-status
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<SupplierResponse>> toggleStatus(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.toggleStatus(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/suppliers/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            // Tüm aktif tedarikçileri çek (silinmemiş)
            var allPage = supplierService.listSuppliers(PageRequest.of(0, Integer.MAX_VALUE), null);
            Map<String, Object> result = new HashMap<>();
            result.put("totalSuppliers", allPage.getTotalElements());
            result.put("activeSuppliers",
                allPage.stream().filter(s -> Boolean.TRUE.equals(s.getIsActive())).count());
            result.put("inactiveSuppliers",
                allPage.stream().filter(s -> !Boolean.TRUE.equals(s.getIsActive())).count());
            result.put("corporateSuppliers",
                allPage.stream()
                    .filter(s -> s.getCustomerType() != null
                        && s.getCustomerType().name().equals("CORPORATE"))
                    .count());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/suppliers/{id}/account
    @GetMapping("/{id}/account")
    public ResponseEntity<ApiResponse<SupplierAccountResponse>> getAccount(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.getSupplierAccount(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/suppliers/{id}/transactions
    @GetMapping("/{id}/transactions")
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> getTransactions(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.getSupplierTransactions(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/v1/suppliers/{id}/payment
    @PostMapping("/{id}/payment")
    public ResponseEntity<ApiResponse<SupplierAccountResponse>> recordPayment(
            @PathVariable String id,
            @RequestBody SupplierPaymentDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierService.recordPayment(id, dto)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Odeme kaydi hatasi: supplierId={}, {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    // PUT /product/api/v1/suppliers/{id}/credit-limit
    @PutMapping("/{id}/credit-limit")
    public ResponseEntity<ApiResponse<SupplierAccountResponse>> updateCreditLimit(
            @PathVariable String id,
            @RequestBody Map<String, BigDecimal> body) {
        try {
            BigDecimal newLimit = body.get("creditLimit");
            if (newLimit == null) {
                throw new TOpenException(new TOpenMessage(TMessageType.SUPPLIER_UPDATE_ERROR_1902));
            }
            return ResponseEntity.ok(ApiResponse.success(supplierService.updateCreditLimit(id, newLimit)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }
}
