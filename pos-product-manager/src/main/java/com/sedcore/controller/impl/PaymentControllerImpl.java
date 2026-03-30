package com.sedcore.controller.impl;

import com.sedcore.controller.PaymentController;
import com.sedcore.model.PaymentRequest;
import com.sedcore.model.PaymentResponse;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
        } catch (Exception e) {
            log.error("Odeme olusturma hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Odeme olusturulamadi: " + e.getMessage()));
        }
    }

    // GET /product/api/v1/payments/{id}
    @Override
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PaymentResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(paymentService.getPayment(id)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
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
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("customerId, supplierId, saleId veya purchaseId parametresi gerekli"));
        } catch (Exception e) {
            log.error("Odeme listesi hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
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
        } catch (Exception e) {
            log.error("Odeme iptal hatasi: id={}, {}", id, e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Odeme iptal edilemedi: " + e.getMessage()));
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
        } catch (Exception e) {
            log.error("Odeme onay hatasi: id={}, {}", id, e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Odeme onaylanamadi: " + e.getMessage()));
        }
    }
}
