package com.sedcore.controller.impl;

import com.sedcore.controller.VehicleCompatibilityController;
import com.sedcore.model.VehicleCompatibilityRequest;
import com.sedcore.model.VehicleCompatibilityResponse;
import com.sedcore.service.VehicleCompatibilityService;
import com.sedcore.se.ApiResponse;
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
        } catch (Exception e) {
            log.error("Uyumlu araclar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/vehicle/{vehicleId}")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> getByVehicleId(@PathVariable String vehicleId) {
        try {
        } catch (Exception e) {
            log.error("Uyumlu parcalar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleCompatibilityResponse>> createCompatibility(@RequestBody VehicleCompatibilityRequest request) {
        try {
            VehicleCompatibilityResponse response = vehicleCompatibilityService.createCompatibility(request);
        } catch (Exception e) {
            log.error("Arac uyumlulugu eklenirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping("/bulk")
    public ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> bulkCreate(@RequestBody VehicleCompatibilityRequest request) {
        try {
            List<VehicleCompatibilityResponse> responses = vehicleCompatibilityService.bulkCreate(request);
        } catch (Exception e) {
            log.error("Toplu arac uyumlulugu eklenirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCompatibility(@PathVariable String id) {
        try {
            vehicleCompatibilityService.deleteCompatibility(id);
        } catch (Exception e) {
            log.error("Arac uyumlulugu silinirken hata: {}", e);
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
        } catch (Exception e) {
            log.error("Uyumluluk aranirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }
}
