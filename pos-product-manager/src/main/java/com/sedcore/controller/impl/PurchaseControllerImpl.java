package com.sedcore.controller.impl;

import com.sedcore.model.PurchaseRequest;
import com.sedcore.model.PurchaseResponse;
import com.sedcore.model.PurchaseReturnRequest;
import com.sedcore.model.PurchaseReturnResponse;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.PurchaseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/product/api/v1/purchases")
@RequiredArgsConstructor
@Slf4j
public class PurchaseControllerImpl {

    private final PurchaseService purchaseService;

    // GET /api/v1/purchases?supplierId=&isCancelled=
    @GetMapping
    public ResponseEntity<ApiResponse<List<PurchaseResponse>>> list(
            @RequestParam(required = false) String supplierId,
            @RequestParam(required = false) Boolean isCancelled
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    purchaseService.listPurchases(supplierId, isCancelled)));
        } catch (Exception e) {
            log.error("Satin alma listesi hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Liste alinamadi: " + e.getMessage()));
        }
    }

    // GET /api/v1/purchases/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PurchaseResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(purchaseService.getPurchase(id)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // POST /api/v1/purchases
    @PostMapping
    public ResponseEntity<ApiResponse<PurchaseResponse>> create(
            @Valid @RequestBody PurchaseRequest request) {
        try {
            PurchaseResponse response = purchaseService.createPurchase(request);
            log.info("Satin alma olusturuldu: fatura={}, tedarikci={}",
                    response.getInvoiceNumber(), response.getSupplierName());
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Satin alma hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Satin alma olusturulamadi: " + e.getMessage()));
        }
    }

    // PUT /api/v1/purchases/{id}
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<PurchaseResponse>> update(
            @PathVariable String id,
            @RequestBody PurchaseRequest request) {
        try {
            PurchaseResponse response = purchaseService.updatePurchase(id, request);
            log.info("Satin alma guncellendi: id={}", id);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Satin alma guncelleme hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Guncelleme basarisiz: " + e.getMessage()));
        }
    }

    // POST /api/v1/purchases/{id}/returns
    @PostMapping("/{id}/returns")
    public ResponseEntity<ApiResponse<PurchaseReturnResponse>> createReturn(
            @PathVariable String id,
            @RequestBody PurchaseReturnRequest request) {
        try {
            PurchaseReturnResponse response = purchaseService.createPurchaseReturn(id, request);
            log.info("Satin alma iadesi olusturuldu: purchaseId={}, tutar={}",
                    id, response.getTotalReturnAmount());
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Satin alma iadesi hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Iade olusturulamadi: " + e.getMessage()));
        }
    }

    // PATCH /api/v1/purchases/{id}/cancel
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<PurchaseResponse>> cancel(@PathVariable String id) {
        try {
            PurchaseResponse response = purchaseService.cancelPurchase(id);
            log.info("Satin alma iptal edildi: id={}", id);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // GET /api/v1/purchases/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            List<PurchaseResponse> all = purchaseService.listPurchases(null, null);
            List<PurchaseResponse> active = purchaseService.listPurchases(null, false);

            BigDecimal totalSpent = active.stream()
                    .map(PurchaseResponse::getTotalAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalDebt = active.stream()
                    .map(PurchaseResponse::getRemainingDebt)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            Map<String, Object> s = new HashMap<>();
            s.put("totalPurchases", all.size());
            s.put("activePurchases", active.size());
            s.put("cancelledPurchases", all.size() - active.size());
            s.put("totalSpent", totalSpent);
            s.put("totalDebt", totalDebt);

            return ResponseEntity.ok(ApiResponse.success(s));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
