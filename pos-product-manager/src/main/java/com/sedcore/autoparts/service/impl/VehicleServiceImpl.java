package com.sedcore.autoparts.service.impl;

import com.sedcore.autoparts.entity.Vehicle;
import com.sedcore.autoparts.model.VehicleRequest;
import com.sedcore.autoparts.model.VehicleResponse;
import com.sedcore.autoparts.repository.VehicleRepository;
import com.sedcore.autoparts.service.VehicleService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class VehicleServiceImpl extends BaseDbServiceImp<VehicleRepository, Vehicle> implements VehicleService {

    @Override
    public Class<?> getDTOClassForService() {
        return VehicleResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleResponse> getActiveVehicles() {
        return dao.findByIsActiveTrueOrderByMakeAscModelAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleResponse> getAllVehicles() {
        return dao.findAllByOrderByMakeAscModelAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public VehicleResponse createVehicle(VehicleRequest request) {
        Vehicle vehicle = Vehicle.builder()
                .make(request.getMake())
                .model(request.getModel())
                .yearStart(request.getYearStart())
                .yearEnd(request.getYearEnd())
                .engineType(request.getEngineType())
                .fuelType(request.getFuelType())
                .bodyType(request.getBodyType())
                .platformCode(request.getPlatformCode())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();
        Vehicle saved = save(vehicle);
        log.info("Arac olusturuldu: {} {} ({}-{}) ({})", saved.getMake(), saved.getModel(),
                saved.getYearStart(), saved.getYearEnd(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public VehicleResponse updateVehicle(String id, VehicleRequest request) {
        Vehicle vehicle = findById(id)
                .orElseThrow(() -> new RuntimeException("Arac bulunamadi: " + id));
        vehicle.setMake(request.getMake());
        vehicle.setModel(request.getModel());
        vehicle.setYearStart(request.getYearStart());
        vehicle.setYearEnd(request.getYearEnd());
        vehicle.setEngineType(request.getEngineType());
        vehicle.setFuelType(request.getFuelType());
        vehicle.setBodyType(request.getBodyType());
        vehicle.setPlatformCode(request.getPlatformCode());
        if (request.getIsActive() != null) vehicle.setIsActive(request.getIsActive());
        Vehicle saved = save(vehicle);
        log.info("Arac guncellendi: {} {} ({})", saved.getMake(), saved.getModel(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public void deleteVehicle(String id) {
        Vehicle vehicle = findById(id)
                .orElseThrow(() -> new RuntimeException("Arac bulunamadi: " + id));
        delete(vehicle);
        log.info("Arac silindi: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> getDistinctMakes() {
        return dao.findDistinctMakes();
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> getModelsByMake(String make) {
        return dao.findDistinctModelsByMake(make);
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleResponse> searchVehicles(String make, String model, Integer year) {
        return dao.searchVehicles(make, model, year).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private VehicleResponse toResponse(Vehicle vehicle) {
        return VehicleResponse.builder()
                .id(vehicle.getId())
                .companyCode(vehicle.getCompanyCode())
                .make(vehicle.getMake())
                .model(vehicle.getModel())
                .yearStart(vehicle.getYearStart())
                .yearEnd(vehicle.getYearEnd())
                .engineType(vehicle.getEngineType())
                .fuelType(vehicle.getFuelType())
                .bodyType(vehicle.getBodyType())
                .platformCode(vehicle.getPlatformCode())
                .isActive(vehicle.getIsActive())
                .build();
    }
}
