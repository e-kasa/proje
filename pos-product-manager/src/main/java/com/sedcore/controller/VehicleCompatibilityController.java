package com.sedcore.controller;

import com.sedcore.model.VehicleCompatibilityRequest;
import com.sedcore.model.VehicleCompatibilityResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface VehicleCompatibilityController {

    ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> getByVariantId(@PathVariable String variantId);

    ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> getByVehicleId(@PathVariable String vehicleId);

    ResponseEntity<ApiResponse<VehicleCompatibilityResponse>> createCompatibility(@RequestBody VehicleCompatibilityRequest request);

    ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> bulkCreate(@RequestBody VehicleCompatibilityRequest request);

    ResponseEntity<ApiResponse<Void>> deleteCompatibility(@PathVariable String id);

    ResponseEntity<ApiResponse<List<VehicleCompatibilityResponse>>> searchByVehicle(
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year);
}
