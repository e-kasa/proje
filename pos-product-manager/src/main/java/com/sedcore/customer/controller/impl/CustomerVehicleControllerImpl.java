package com.sedcore.customer.controller.impl;

import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.customer.model.CustomerVehicleDto;
import com.sedcore.customer.model.CustomerVehicleResponse;
import com.sedcore.customer.service.CustomerVehicleService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Sprint 9 — CustomerVehicle REST endpoint'leri.
 *
 * <p>POS satış akışında plaka picker autocomplete kullanır;
 * AccountsHub statement panelinde plaka filter UI ile kullanılır.
 */
@RestController
@RequestMapping("api/v1/customers/{customerId}/vehicles")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Customer Vehicles", description = "Müşteriye bağlı plaka kayıtları (Sprint 9)")
@SecurityRequirement(name = "Bearer Authentication")
public class CustomerVehicleControllerImpl {

    private final CustomerVehicleService service;

    /** GET /product/api/v1/customers/{customerId}/vehicles — aktif plakalar */
    @GetMapping
    @Transactional(readOnly = true)
    @Operation(summary = "Müşterinin aktif plakaları")
    public ResponseEntity<ApiResponse<List<CustomerVehicleResponse>>> list(
            @PathVariable String customerId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.listByCustomer(customerId)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle list hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    /** GET .../vehicles/search?q=34A — autocomplete */
    @GetMapping("/search")
    @Transactional(readOnly = true)
    @Operation(summary = "Plaka prefix arama (autocomplete)")
    public ResponseEntity<ApiResponse<List<CustomerVehicleResponse>>> search(
            @PathVariable String customerId,
            @RequestParam(required = false) String q) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.searchByCustomer(customerId, q)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle search hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    /** GET .../vehicles/{id} — tek kayıt */
    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<CustomerVehicleResponse>> getById(
            @PathVariable String customerId, @PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    service.findById(id).orElseThrow(() ->
                            new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)))));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle getById hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    /** POST .../vehicles — yeni plaka (idempotent) */
    @PostMapping
    public ResponseEntity<ApiResponse<CustomerVehicleResponse>> create(
            @PathVariable String customerId,
            @Valid @RequestBody CustomerVehicleDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.create(customerId, dto)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle create hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    /** PUT .../vehicles/{id} — güncelleme */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerVehicleResponse>> update(
            @PathVariable String customerId,
            @PathVariable String id,
            @RequestBody CustomerVehicleDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.update(id, dto)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle update hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    /** DELETE .../vehicles/{id} — soft-delete (isActive=false) */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerVehicleResponse>> deactivate(
            @PathVariable String customerId, @PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(service.deactivate(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("CustomerVehicle deactivate hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
