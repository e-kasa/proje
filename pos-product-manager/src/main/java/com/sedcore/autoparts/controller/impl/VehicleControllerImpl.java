package com.sedcore.autoparts.controller.impl;

import com.sedcore.autoparts.controller.VehicleController;
import com.sedcore.autoparts.model.VehicleRequest;
import com.sedcore.autoparts.model.VehicleResponse;
import com.sedcore.autoparts.service.VehicleService;
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
@RequestMapping("/api/vehicle")
public class VehicleControllerImpl implements VehicleController {

    private final VehicleService vehicleService;

    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getActiveVehicles() {
        try {
            List<VehicleResponse> vehicles = vehicleService.getActiveVehicles();
            return ResponseEntity.ok(ApiResponse.success(vehicles));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getAllVehicles() {
        try {
            List<VehicleResponse> vehicles = vehicleService.getAllVehicles();
            return ResponseEntity.ok(ApiResponse.success(vehicles));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleResponse>> createVehicle(@RequestBody VehicleRequest request) {
        try {
            VehicleResponse response = vehicleService.createVehicle(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleResponse>> updateVehicle(@PathVariable String id, @RequestBody VehicleRequest request) {
        try {
            VehicleResponse response = vehicleService.updateVehicle(id, request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable String id) {
        try {
            vehicleService.deleteVehicle(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/makes")
    public ResponseEntity<ApiResponse<List<String>>> getDistinctMakes() {
        try {
            List<String> makes = vehicleService.getDistinctMakes();
            return ResponseEntity.ok(ApiResponse.success(makes));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/models")
    public ResponseEntity<ApiResponse<List<String>>> getModelsByMake(@RequestParam String make) {
        try {
            List<String> models = vehicleService.getModelsByMake(make);
            return ResponseEntity.ok(ApiResponse.success(models));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
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
            List<VehicleResponse> vehicles = vehicleService.searchVehicles(make, model, year);
            return ResponseEntity.ok(ApiResponse.success(vehicles));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }
}
