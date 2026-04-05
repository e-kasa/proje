package com.sedcore.service.impl;

import com.sedcore.entity.OemNumber;
import com.sedcore.entity.ProductVariant;
import com.sedcore.model.OemNumberRequest;
import com.sedcore.model.OemNumberResponse;
import com.sedcore.repository.OemNumberRepository;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.service.OemNumberService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class OemNumberServiceImpl extends BaseDbServiceImp<OemNumberRepository, OemNumber> implements OemNumberService {

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return OemNumberResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<OemNumberResponse> getByVariantId(String variantId) {
        return dao.findByVariantIdOrderByIsPrimaryDesc(variantId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public OemNumberResponse createOemNumber(OemNumberRequest request) {
        ProductVariant variant = productVariantRepository.findById(request.getVariantId())
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + request.getVariantId()));
        OemNumber oem = OemNumber.builder()
                .variant(variant)
                .oemNumber(request.getOemNumber())
                .manufacturer(request.getManufacturer())
                .isPrimary(request.getIsPrimary() != null ? request.getIsPrimary() : false)
                .build();
        OemNumber saved = save(oem);
        log.info("OEM numarasi eklendi: {} (varyant: {})", saved.getOemNumber(), variant.getId());
        return toResponse(saved);
    }

    @Override
    public List<OemNumberResponse> bulkCreate(String variantId, List<OemNumberRequest> requests) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + variantId));
        List<OemNumberResponse> responses = new ArrayList<>();
        for (OemNumberRequest request : requests) {
            OemNumber oem = OemNumber.builder()
                    .variant(variant)
                    .oemNumber(request.getOemNumber())
                    .manufacturer(request.getManufacturer())
                    .isPrimary(request.getIsPrimary() != null ? request.getIsPrimary() : false)
                    .build();
            responses.add(toResponse(save(oem)));
        }
        log.info("{} adet OEM numarasi eklendi (varyant: {})", responses.size(), variantId);
        return responses;
    }

    @Override
    public void deleteOemNumber(String id) {
        OemNumber oem = findById(id)
                .orElseThrow(() -> new RuntimeException("OEM numarasi bulunamadi: " + id));
        delete(oem);
        log.info("OEM numarasi silindi: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OemNumberResponse> searchByOemNumber(String q) {
        return dao.searchByOemNumber(q).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private OemNumberResponse toResponse(OemNumber oem) {
        return OemNumberResponse.builder()
                .id(oem.getId())
                .variantId(oem.getVariant().getId())
                .oemNumber(oem.getOemNumber())
                .manufacturer(oem.getManufacturer())
                .isPrimary(oem.getIsPrimary())
                .build();
    }
}
