package com.sedcore.product.service.impl;

import com.sedcore.product.entity.Brand;
import com.sedcore.product.model.BrandRequest;
import com.sedcore.product.model.BrandResponse;
import com.sedcore.product.repository.BrandRepository;
import com.sedcore.product.service.BrandService;
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
public class BrandServiceImpl extends BaseDbServiceImp<BrandRepository, Brand> implements BrandService {

    @Override
    public Class<?> getDTOClassForService() {
        return BrandResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<BrandResponse> getActiveBrands() {
        return dao.findByIsActiveTrueOrderByNameAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<BrandResponse> getAllBrands() {
        return dao.findAllByOrderByNameAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public BrandResponse createBrand(BrandRequest request) {
        Brand brand = Brand.builder()
                .name(request.getName())
                .code(request.getCode())
                .description(request.getDescription())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();
        Brand saved = save(brand);
        log.info("Marka oluşturuldu: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public BrandResponse updateBrand(String id, BrandRequest request) {
        Brand brand = findById(id)
                .orElseThrow(() -> new RuntimeException("Marka bulunamadı: " + id));
        brand.setName(request.getName());
        brand.setCode(request.getCode());
        brand.setDescription(request.getDescription());
        if (request.getIsActive() != null) brand.setIsActive(request.getIsActive());
        Brand saved = save(brand);
        log.info("Marka güncellendi: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    @Override
    public void deleteBrand(String id) {
        Brand brand = findById(id)
                .orElseThrow(() -> new RuntimeException("Marka bulunamadı: " + id));
        delete(brand);
        log.info("Marka silindi: {}", id);
    }

    @Override
    public BrandResponse toggleStatus(String id) {
        Brand brand = findById(id)
                .orElseThrow(() -> new RuntimeException("Marka bulunamadı: " + id));
        brand.setIsActive(!Boolean.TRUE.equals(brand.getIsActive()));
        Brand saved = save(brand);
        log.info("Marka durumu değişti: {} → isActive={}", saved.getName(), saved.getIsActive());
        return toResponse(saved);
    }

    private BrandResponse toResponse(Brand brand) {
        return BrandResponse.builder()
                .id(brand.getId())
                .companyCode(brand.getCompanyCode())
                .name(brand.getName())
                .code(brand.getCode())
                .description(brand.getDescription())
                .isActive(brand.getIsActive())
                .build();
    }
}
