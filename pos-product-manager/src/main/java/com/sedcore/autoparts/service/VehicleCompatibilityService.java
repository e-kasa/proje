package com.sedcore.autoparts.service;

import com.sedcore.autoparts.entity.VehicleCompatibility;
import com.sedcore.autoparts.model.VehicleCompatibilityRequest;
import com.sedcore.autoparts.model.VehicleCompatibilityResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface VehicleCompatibilityService extends BaseDbService<VehicleCompatibility> {

    List<VehicleCompatibilityResponse> getByVariantId(String variantId);

    List<VehicleCompatibilityResponse> getByVehicleId(String vehicleId);

    VehicleCompatibilityResponse createCompatibility(VehicleCompatibilityRequest request);

    List<VehicleCompatibilityResponse> bulkCreate(VehicleCompatibilityRequest request);

    void deleteCompatibility(String id);

    List<VehicleCompatibilityResponse> searchByVehicle(String make, String model, Integer year);
}
