package com.sedcore.controller.impl;

import com.sedcore.controller.VehicleCompatibilityController;
import com.sedcore.model.VehicleCompatibilityRequest;
import com.sedcore.model.VehicleCompatibilityResponse;
import com.sedcore.service.VehicleCompatibilityService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/vehicle-compatibility")
public class VehicleCompatibilityControllerImpl implements VehicleCompatibilityController {

    private final VehicleCompatibilityService vehicleCompatibilityService;

    @Override
    @GetMapping("/variant/{variantId}")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> getByVariantId(@PathVariable String variantId) {
        try {
            List<VehicleCompatibilityResponse> responses = vehicleCompatibilityService.getByVariantId(variantId);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/vehicle/{vehicleId}")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> getByVehicleId(@PathVariable String vehicleId) {
        try {
            List<VehicleCompatibilityResponse> responses = vehicleCompatibilityService.getByVehicleId(vehicleId);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleCompatibilityResponse>> createCompatibility(@RequestBody VehicleCompatibilityRequest request) {
        try {
            VehicleCompatibilityResponse response = vehicleCompatibilityService.createCompatibility(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping("/bulk")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> bulkCreate(@RequestBody VehicleCompatibilityRequest request) {
        try {
            List<VehicleCompatibilityResponse> responses = vehicleCompatibilityService.bulkCreate(request);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCompatibility(@PathVariable String id) {
        try {
            vehicleCompatibilityService.deleteCompatibility(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> searchByVehicle(
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year) {
        try {
            List<VehicleCompatibilityResponse> responses = vehicleCompatibilityService.searchByVehicle(make, model, year);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }
}
