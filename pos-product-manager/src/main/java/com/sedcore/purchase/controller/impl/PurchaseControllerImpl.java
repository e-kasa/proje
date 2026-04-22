package com.sedcore.purchase.controller.impl;

import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.PurchaseDiscountRequest;
import com.sedcore.purchase.model.PurchaseRequest;
import com.sedcore.purchase.model.PurchaseResponse;
import com.sedcore.purchase.model.PurchaseReturnRequest;
import com.sedcore.purchase.model.PurchaseReturnResponse;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.purchase.service.PurchaseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/purchases")
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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "listPurchases");
        }
    }

    // GET /api/v1/purchases/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PurchaseResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(purchaseService.getPurchase(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.notFound("Purchase[" + id + "]");
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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "createPurchase");
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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "updatePurchase(" + id + ")");
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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "createPurchaseReturn(" + id + ")");
        }
    }

    // PATCH /api/v1/purchases/{id}/cancel
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<PurchaseResponse>> cancel(@PathVariable String id) {
        try {
            PurchaseResponse response = purchaseService.cancelPurchase(id);
            log.info("Satin alma iptal edildi: id={}", id);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "cancelPurchase(" + id + ")");
        }
    }

    // POST /api/v1/purchases/{id}/discount
    @PostMapping("/{id}/discount")
    public ResponseEntity<ApiResponse<PurchaseResponse>> applyDiscount(
            @PathVariable String id,
            @Valid @RequestBody PurchaseDiscountRequest request) {
        try {
            PurchaseResponse response = purchaseService.applyDiscount(id, request);
            log.info("Iskonto uygulandi: purchaseId={}, tutar={}", id, request.getDiscountAmount());
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "applyDiscount(" + id + ")");
        }
    }

    // GET /api/v1/purchases/{id}/claims
    @GetMapping("/{id}/claims")
    public ResponseEntity<ApiResponse<List<SupplierClaimResponse>>> listClaims(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(purchaseService.listClaims(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "listClaims(" + id + ")");
        }
    }

    // GET /api/v1/purchases/claims/supplier/{supplierId}?status=
    @GetMapping("/claims/supplier/{supplierId}")
    public ResponseEntity<ApiResponse<List<SupplierClaimResponse>>> listClaimsBySupplier(
            @PathVariable String supplierId,
            @RequestParam(required = false) ClaimStatus status) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    purchaseService.listClaimsBySupplier(supplierId, status)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "listClaimsBySupplier(" + supplierId + ")");
        }
    }

    // PATCH /api/v1/purchases/claims/{claimId}/resolve
    @PatchMapping("/claims/{claimId}/resolve")
    public ResponseEntity<ApiResponse<SupplierClaimResponse>> resolveClaim(
            @PathVariable String claimId,
            @Valid @RequestBody ClaimResolveRequest request) {
        try {
            SupplierClaimResponse response = purchaseService.resolveClaim(claimId, request);
            log.info("Claim kapatildi: claimId={}, resolution={}", claimId, request.getResolution());
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "resolveClaim(" + claimId + ")");
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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "getPurchaseStats");
        }
    }
}