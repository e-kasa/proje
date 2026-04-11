package com.sedcore.autoparts.controller;

import com.sedcore.autoparts.model.VehicleRequest;
import com.sedcore.autoparts.model.VehicleResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface VehicleController {

    ResponseEntity<ApiResponse<List<VehicleResponse>>> getActiveVehicles();

    ResponseEntity<ApiResponse<List<VehicleResponse>>> getAllVehicles();

    ResponseEntity<ApiResponse<VehicleResponse>> createVehicle(@RequestBody VehicleRequest request);

    ResponseEntity<ApiResponse<VehicleResponse>> updateVehicle(@PathVariable String id, @RequestBody VehicleRequest request);

    ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable String id);

    ResponseEntity<ApiResponse<List<String>>> getDistinctMakes();

    ResponseEntity<ApiResponse<List<String>>> getModelsByMake(@RequestParam String make);

    ResponseEntity<ApiResponse<List<VehicleResponse>>> searchVehicles(
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year);
}
