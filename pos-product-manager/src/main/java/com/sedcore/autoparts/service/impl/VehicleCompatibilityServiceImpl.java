package com.sedcore.autoparts.service.impl;

import com.sedcore.product.entity.ProductVariant;
import com.sedcore.autoparts.entity.Vehicle;
import com.sedcore.autoparts.entity.VehicleCompatibility;
import com.sedcore.autoparts.model.VehicleCompatibilityRequest;
import com.sedcore.autoparts.model.VehicleCompatibilityResponse;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.autoparts.repository.VehicleCompatibilityRepository;
import com.sedcore.autoparts.repository.VehicleRepository;
import com.sedcore.autoparts.service.VehicleCompatibilityService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class VehicleCompatibilityServiceImpl extends BaseDbServiceImp<VehicleCompatibilityRepository, VehicleCompatibility>
        implements VehicleCompatibilityService {

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return VehicleCompatibilityResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleCompatibilityResponse> getByVariantId(String variantId) {
        return dao.findByVariantId(variantId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleCompatibilityResponse> getByVehicleId(String vehicleId) {
        return dao.findByVehicleId(vehicleId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public VehicleCompatibilityResponse createCompatibility(VehicleCompatibilityRequest request) {
        ProductVariant variant = productVariantRepository.findById(request.getVariantId())
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + request.getVariantId()));
        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
                .orElseThrow(() -> new RuntimeException("Arac bulunamadi: " + request.getVehicleId()));

        VehicleCompatibility vc = VehicleCompatibility.builder()
                .variant(variant)
                .vehicle(vehicle)
                .notes(request.getNotes())
                .isVerified(request.getIsVerified() != null ? request.getIsVerified() : false)
                .build();
        VehicleCompatibility saved = save(vc);
        log.info("Arac uyumlulugu eklendi: {} {} -> varyant {}", vehicle.getMake(), vehicle.getModel(), variant.getId());
        return toResponse(saved);
    }

    @Override
    public List<VehicleCompatibilityResponse> bulkCreate(VehicleCompatibilityRequest request) {
        ProductVariant variant = productVariantRepository.findById(request.getVariantId())
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + request.getVariantId()));

        List<VehicleCompatibilityResponse> responses = new ArrayList<>();
        for (String vehicleId : request.getVehicleIds()) {
            Vehicle vehicle = vehicleRepository.findById(vehicleId)
                    .orElseThrow(() -> new RuntimeException("Arac bulunamadi: " + vehicleId));
            VehicleCompatibility vc = VehicleCompatibility.builder()
                    .variant(variant)
                    .vehicle(vehicle)
                    .notes(request.getNotes())
                    .isVerified(request.getIsVerified() != null ? request.getIsVerified() : false)
                    .build();
            responses.add(toResponse(save(vc)));
        }
        log.info("{} adet arac uyumlulugu eklendi (varyant: {})", responses.size(), variant.getId());
        return responses;
    }

    @Override
    public void deleteCompatibility(String id) {
        VehicleCompatibility vc = findById(id)
                .orElseThrow(() -> new RuntimeException("Arac uyumlulugu bulunamadi: " + id));
        delete(vc);
        log.info("Arac uyumlulugu silindi: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<VehicleCompatibilityResponse> searchByVehicle(String make, String model, Integer year) {
        return dao.searchByVehicle(make, model, year).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private VehicleCompatibilityResponse toResponse(VehicleCompatibility vc) {
        Vehicle vehicle = vc.getVehicle();
        ProductVariant variant = vc.getVariant();
        return VehicleCompatibilityResponse.builder()
                .id(vc.getId())
                .variantId(variant.getId())
                .variantSku(variant.getSku())
                .variantName(variant.getName())
                .vehicleId(vehicle.getId())
                .vehicleMake(vehicle.getMake())
                .vehicleModel(vehicle.getModel())
                .vehicleYearStart(vehicle.getYearStart())
                .vehicleYearEnd(vehicle.getYearEnd())
                .vehicleEngineType(vehicle.getEngineType())
                .notes(vc.getNotes())
                .isVerified(vc.getIsVerified())
                .build();
    }
}
