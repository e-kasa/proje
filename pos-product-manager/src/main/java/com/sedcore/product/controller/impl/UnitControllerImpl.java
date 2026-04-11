package com.sedcore.product.controller.impl;

import com.sedcore.product.controller.UnitController;
import com.sedcore.product.model.UnitRequest;
import com.sedcore.product.model.UnitResponse;
import com.sedcore.product.service.UnitService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/unit")
public class UnitControllerImpl implements UnitController {

    private final UnitService unitService;

    // GET /product/api/unit
    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getActiveUnits() {
        try {
            List<UnitResponse> units = unitService.getActiveUnits();
            return ResponseEntity.ok(ApiResponse.success(units));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/unit/all
    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getAllUnits() {
        try {
            List<UnitResponse> units = unitService.getAllUnits();
            return ResponseEntity.ok(ApiResponse.success(units));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/unit
    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<UnitResponse>> createUnit(@RequestBody UnitRequest request) {
        try {
            UnitResponse response = unitService.createUnit(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PUT /product/api/unit/{id}
    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UnitResponse>> updateUnit(@PathVariable String id, @RequestBody UnitRequest request) {
        try {
            UnitResponse response = unitService.updateUnit(id, request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // DELETE /product/api/unit/{id}
    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUnit(@PathVariable String id) {
        try {
            unitService.deleteUnit(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PATCH /product/api/unit/{id}/toggle-status
    @Override
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<UnitResponse>> toggleStatus(@PathVariable String id) {
        try {
            UnitResponse response = unitService.toggleStatus(id);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }
}
