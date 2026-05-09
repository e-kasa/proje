package com.sedcore.customer.controller.impl;

import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.customer.model.VehicleSearchResponse;
import com.sedcore.customer.service.CustomerVehicleService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Sprint 11e — Tenant-wide plaka arama endpoint'i.
 *
 * <p>Senaryo: parçacı/tamirhane sektöründe ödeme yapmaya gelen kişi araç sahibi
 * olabilir; müşteri ismi BİLİNMEZ. Plaka prefix yazınca müşteri+plaka eşleşmeleri
 * ile her satırda açık satış sayısı + açık kalan tutar listelenir.</p>
 *
 * <p>{@link CustomerVehicleControllerImpl} {@code /customers/{id}/vehicles}
 * altında müşteri-bağlı CRUD/search yapar; bu controller customer-bağımsız
 * tenant-wide arama için ayrı yol sağlar (path scope ayrımı).</p>
 */
@RestController
@RequestMapping("api/v1/vehicles")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Vehicle Search", description = "Tenant-wide plaka arama (Sprint 11e)")
@SecurityRequirement(name = "Bearer Authentication")
public class VehicleSearchControllerImpl {

    private final CustomerVehicleService service;

    /**
     * GET /product/api/v1/vehicles/search?q=34A&limit=20
     *
     * @param q     plaka prefix (en az 1 karakter; normalize edilir)
     * @param limit sonuç sayısı (1-100, default 20)
     */
    @GetMapping("/search")
    @Transactional(readOnly = true)
    @Operation(summary = "Tenant-wide plaka prefix arama (müşteri ismi bilinmeden)")
    public ResponseEntity<ApiResponse<List<VehicleSearchResponse>>> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false, defaultValue = "20") int limit) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.searchAcrossTenant(q, limit)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("VehicleSearch hatası q={}, limit={}", q, limit, e);
            throw ExceptionMapper.map(e);
        }
    }
}
