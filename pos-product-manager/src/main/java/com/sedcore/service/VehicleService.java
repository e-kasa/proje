package com.sedcore.service;

import com.sedcore.entity.Vehicle;
import com.sedcore.model.VehicleRequest;
import com.sedcore.model.VehicleResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface VehicleService extends BaseDbService<Vehicle> {

    List<VehicleResponse> getActiveVehicles();

    List<VehicleResponse> getAllVehicles();

    VehicleResponse createVehicle(VehicleRequest request);

    VehicleResponse updateVehicle(String id, VehicleRequest request);

    void deleteVehicle(String id);

    List<String> getDistinctMakes();

    List<String> getModelsByMake(String make);

    List<VehicleResponse> searchVehicles(String make, String model, Integer year);
}
