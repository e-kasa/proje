package com.sedcore.purchase.controller.impl;

import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.sedcore.purchase.service.SupplierClaimService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Tedarikçi alacak talepleri (SupplierClaim) için REST endpoint'leri.
 *
 * <p>Batch girişten veya direkt Purchase oluşturmadan doğan eksik teslimat kayıtlarının
 * listelenmesi, detayı, çözümü ve iptali burada yönetilir.</p>
 *
 * <p>Flutter URL prefix'i: {@code product/api/v1/supplier-claims/...}</p>
 */
@RestController
@RequestMapping("/api/v1/supplier-claims")
@RequiredArgsConstructor
@Slf4j
public class SupplierClaimControllerImpl {

    private final SupplierClaimService supplierClaimService;

    // GET /api/v1/supplier-claims?status=OPEN&supplierId=
    @GetMapping
    public ResponseEntity<ApiResponse<List<SupplierClaimResponse>>> list(
            @RequestParam(required = false) ClaimStatus status,
            @RequestParam(required = false) String supplierId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    supplierClaimService.listClaims(supplierId, status)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Talep listesi alınamadı", e);
            throw ExceptionMapper.mapAndLog(e, "listSupplierClaims");
        }
    }

    // GET /api/v1/supplier-claims/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SupplierClaimResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(supplierClaimService.getDetail(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Talep detayı alınamadı", e);
            throw ExceptionMapper.notFound("SupplierClaim[" + id + "]");
        }
    }

    // GET /api/v1/supplier-claims/by-purchase/{purchaseId}
    @GetMapping("/by-purchase/{purchaseId}")
    public ResponseEntity<ApiResponse<List<SupplierClaimResponse>>> listByPurchase(
            @PathVariable String purchaseId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    supplierClaimService.listByPurchase(purchaseId)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Purchase talepleri alınamadı", e);
            throw ExceptionMapper.mapAndLog(e, "listByPurchase(" + purchaseId + ")");
        }
    }

    // PATCH /api/v1/supplier-claims/{id}/resolve
    @PatchMapping("/{id}/resolve")
    public ResponseEntity<ApiResponse<SupplierClaimResponse>> resolve(
            @PathVariable String id,
            @Valid @RequestBody ClaimResolveRequest request) {
        try {
            SupplierClaimResponse resp = supplierClaimService.resolveClaim(id, request);
            log.info("Talep kapatıldı: id={}, resolution={}", id, request.getResolution());
            return ResponseEntity.ok(ApiResponse.success(resp));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Talep kapatılamadı", e);
            throw ExceptionMapper.mapAndLog(e, "resolveClaim(" + id + ")");
        }
    }

    // PATCH /api/v1/supplier-claims/{id}/cancel
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<SupplierClaimResponse>> cancel(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.get("reason") : null;
            SupplierClaimResponse resp = supplierClaimService.cancelClaim(id, reason);
            log.info("Talep iptal edildi: id={}, sebep={}", id, reason);
            return ResponseEntity.ok(ApiResponse.success(resp));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Talep iptal edilemedi", e);
            throw ExceptionMapper.mapAndLog(e, "cancelClaim(" + id + ")");
        }
    }

    // GET /api/v1/supplier-claims/suppliers/{supplierId}/open-total
    @GetMapping("/suppliers/{supplierId}/open-total")
    public ResponseEntity<ApiResponse<Map<String, Object>>> openClaimTotal(
            @PathVariable String supplierId) {
        try {
            BigDecimal total = supplierClaimService.openClaimTotal(supplierId);
            Map<String, Object> body = new HashMap<>();
            body.put("supplierId", supplierId);
            body.put("openClaimTotal", total);
            return ResponseEntity.ok(ApiResponse.success(body));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Açık talep toplamı alınamadı", e);
            throw ExceptionMapper.mapAndLog(e, "openClaimTotal(" + supplierId + ")");
        }
    }
}
