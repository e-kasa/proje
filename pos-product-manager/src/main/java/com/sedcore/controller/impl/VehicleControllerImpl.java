package com.sedcore.controller.impl;

import com.sedcore.controller.VehicleController;
import com.sedcore.model.VehicleRequest;
import com.sedcore.model.VehicleResponse;
import com.sedcore.service.VehicleService;
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
@RequestMapping("/api/vehicle")
public class VehicleControllerImpl implements VehicleController {

    private final VehicleService vehicleService;

    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getActiveVehicles() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Araclar getirildi", vehicleService.getActiveVehicles()));
        } catch (Exception e) {
            log.error("Araclar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getAllVehicles() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Tum araclar getirildi", vehicleService.getAllVehicles()));
        } catch (Exception e) {
            log.error("Tum araclar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleResponse>> createVehicle(@RequestBody VehicleRequest request) {
        try {
            VehicleResponse response = vehicleService.createVehicle(request);
            return ResponseEntity.ok(ApiResponse.success("Arac olusturuldu", response));
        } catch (Exception e) {
            log.error("Arac olusturulurken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleResponse>> updateVehicle(@PathVariable String id, @RequestBody VehicleRequest request) {
        try {
            VehicleResponse response = vehicleService.updateVehicle(id, request);
            return ResponseEntity.ok(ApiResponse.success("Arac guncellendi", response));
        } catch (Exception e) {
            log.error("Arac guncellenirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable String id) {
        try {
            vehicleService.deleteVehicle(id);
            return ResponseEntity.ok(ApiResponse.success("Arac silindi", null));
        } catch (Exception e) {
            log.error("Arac silinirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/makes")
    public ResponseEntity<ApiResponse<List<String>>> getDistinctMakes() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Markalar getirildi", vehicleService.getDistinctMakes()));
        } catch (Exception e) {
            log.error("Markalar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/models")
    public ResponseEntity<ApiResponse<List<String>>> getModelsByMake(@RequestParam String make) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Modeller getirildi", vehicleService.getModelsByMake(make)));
        } catch (Exception e) {
            log.error("Modeller getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> searchVehicles(
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Arama sonuclari", vehicleService.searchVehicles(make, model, year)));
        } catch (Exception e) {
            log.error("Arac aranirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }
}
