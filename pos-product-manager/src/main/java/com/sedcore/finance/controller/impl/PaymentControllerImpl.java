package com.sedcore.finance.controller.impl;

import com.sedcore.finance.controller.PaymentController;
import com.sedcore.finance.model.PaymentRequest;
import com.sedcore.finance.model.PaymentResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.finance.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

import java.util.List;
import java.util.Map;

/**
 * Ödeme Controller
 *
 * POST   /product/api/v1/payments                         → Yeni ödeme (müşteri veya tedarikçi)
 * GET    /product/api/v1/payments/{id}                    → Tek ödeme
 * GET    /product/api/v1/payments?customerId=             → Müşteri ödemeleri
 * GET    /product/api/v1/payments?supplierId=             → Tedarikçi ödemeleri
 * GET    /product/api/v1/payments?saleId=                 → Satışa ait ödemeler
 * GET    /product/api/v1/payments?purchaseId=             → Satın almaya ait ödemeler
 * PATCH  /product/api/v1/payments/{id}/cancel             → İptal  { "reason": "..." }
 * PATCH  /product/api/v1/payments/{id}/verify             → Onay   { "verifiedBy": "..." }
 */
@RestController
@RequestMapping("api/v1/payments")
@RequiredArgsConstructor
@Slf4j
public class PaymentControllerImpl implements PaymentController {

    private final PaymentService paymentService;

    // POST /product/api/v1/payments
    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<PaymentResponse>> create(
            @Valid @RequestBody PaymentRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(paymentService.createPayment(request)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Odeme olusturma hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/payments/{id}
    @Override
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PaymentResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(paymentService.getPayment(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Filtrelenmiş liste:
     *   ?customerId=xxx   → Müşteri ödemeleri
     *   ?supplierId=xxx   → Tedarikçi ödemeleri
     *   ?saleId=xxx       → Satışa ait ödemeler
     *   ?purchaseId=xxx   → Satın almaya ait ödemeler
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> list(
            @RequestParam(required = false) String customerId,
            @RequestParam(required = false) String supplierId,
            @RequestParam(required = false) String saleId,
            @RequestParam(required = false) String purchaseId
    ) {
        try {
            if (customerId != null) {
                return ResponseEntity.ok(ApiResponse.success(paymentService.getByCustomer(customerId)));
            }
            if (supplierId != null) {
                return ResponseEntity.ok(ApiResponse.success(paymentService.getBySupplier(supplierId)));
            }
            if (saleId != null) {
                return ResponseEntity.ok(ApiResponse.success(paymentService.getBySale(saleId)));
            }
            if (purchaseId != null) {
                return ResponseEntity.ok(ApiResponse.success(paymentService.getByPurchase(purchaseId)));
            }
            // Filtresiz — firmaya ait tum odemeler (AccountsHub).
            return ResponseEntity.ok(ApiResponse.success(paymentService.getAll()));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Odeme listesi hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    // Interface metodları — list()'e delegate eder
    @Override
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> listByCustomer(String customerId) {
        return list(customerId, null, null, null);
    }

    @Override
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> listBySupplier(String supplierId) {
        return list(null, supplierId, null, null);
    }

    @Override
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> listBySale(String saleId) {
        return list(null, null, saleId, null);
    }

    @Override
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> listByPurchase(String purchaseId) {
        return list(null, null, null, purchaseId);
    }

    // PATCH /product/api/v1/payments/{id}/cancel
    @Override
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<PaymentResponse>> cancel(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.get("reason") : null;
            return ResponseEntity.ok(ApiResponse.success(paymentService.cancelPayment(id, reason)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Odeme iptal hatasi: id={}, {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    // PATCH /product/api/v1/payments/{id}/verify
    @Override
    @PatchMapping("/{id}/verify")
    public ResponseEntity<ApiResponse<PaymentResponse>> verify(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String verifiedBy = body != null ? body.get("verifiedBy") : null;
            return ResponseEntity.ok(ApiResponse.success(paymentService.verifyPayment(id, verifiedBy)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Odeme onay hatasi: id={}, {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }
}