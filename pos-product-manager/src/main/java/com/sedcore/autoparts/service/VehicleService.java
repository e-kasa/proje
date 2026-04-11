package com.sedcore.autoparts.service;

import com.sedcore.autoparts.entity.Vehicle;
import com.sedcore.autoparts.model.VehicleRequest;
import com.sedcore.autoparts.model.VehicleResponse;
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
