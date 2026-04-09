package com.sedcore.service.impl;

import com.sedcore.entity.Unit;
import com.sedcore.model.UnitRequest;
import com.sedcore.model.UnitResponse;
import com.sedcore.repository.UnitRepository;
import com.sedcore.service.UnitService;
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
public class UnitServiceImpl extends BaseDbServiceImp<UnitRepository, Unit> implements UnitService {

    @Override
    public Class<?> getDTOClassForService() {
        return UnitResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<UnitResponse> getActiveUnits() {
        return dao.findByIsActiveTrueOrderByNameAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<UnitResponse> getAllUnits() {
        return dao.findAllByOrderByNameAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public UnitResponse createUnit(UnitRequest request) {
        Unit unit = Unit.builder()
                .code(request.getCode().toUpperCase())
                .name(request.getName())
                .symbol(request.getSymbol())
                .type(request.getType())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();
        Unit saved = save(unit);
        log.info("Birim oluşturuldu: {} ({}) - {}", saved.getName(), saved.getCode(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public UnitResponse updateUnit(String id, UnitRequest request) {
        Unit unit = findById(id)
                .orElseThrow(() -> new RuntimeException("Birim bulunamadı: " + id));
        unit.setCode(request.getCode().toUpperCase());
        unit.setName(request.getName());
        unit.setSymbol(request.getSymbol());
        unit.setType(request.getType());
        if (request.getIsActive() != null) unit.setIsActive(request.getIsActive());
        Unit saved = save(unit);
        log.info("Birim güncellendi: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public void deleteUnit(String id) {
        Unit unit = findById(id)
                .orElseThrow(() -> new RuntimeException("Birim bulunamadı: " + id));
        delete(unit);
        log.info("Birim silindi: {}", id);
    }

    @Override
    public UnitResponse toggleStatus(String id) {
        Unit unit = findById(id)
                .orElseThrow(() -> new RuntimeException("Birim bulunamadı: " + id));
        unit.setIsActive(!Boolean.TRUE.equals(unit.getIsActive()));
        Unit saved = save(unit);
        log.info("Birim durumu değişti: {} → isActive={}", saved.getName(), saved.getIsActive());
        return toResponse(saved);
    }

    private UnitResponse toResponse(Unit unit) {
        return UnitResponse.builder()
                .id(unit.getId())
                .companyCode(unit.getCompanyCode())
                .code(unit.getCode())
                .name(unit.getName())
                .symbol(unit.getSymbol())
                .type(unit.getType())
                .isActive(unit.getIsActive())
                .build();
    }
}
