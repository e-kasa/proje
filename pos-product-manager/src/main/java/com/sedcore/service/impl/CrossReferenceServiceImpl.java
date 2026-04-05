package com.sedcore.service.impl;

import com.sedcore.entity.CrossReference;
import com.sedcore.entity.ProductVariant;
import com.sedcore.model.CrossReferenceRequest;
import com.sedcore.model.CrossReferenceResponse;
import com.sedcore.repository.CrossReferenceRepository;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.service.CrossReferenceService;
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
public class CrossReferenceServiceImpl extends BaseDbServiceImp<CrossReferenceRepository, CrossReference> implements CrossReferenceService {

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return CrossReferenceResponse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<CrossReferenceResponse> getByVariantId(String variantId) {
        return dao.findByVariantIdOrderByCrossRefBrandAsc(variantId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public CrossReferenceResponse createCrossReference(CrossReferenceRequest request) {
        ProductVariant variant = productVariantRepository.findById(request.getVariantId())
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + request.getVariantId()));
        CrossReference cr = CrossReference.builder()
                .variant(variant)
                .crossRefNumber(request.getCrossRefNumber())
                .crossRefBrand(request.getCrossRefBrand())
                .notes(request.getNotes())
                .build();
        CrossReference saved = save(cr);
        log.info("Capraz referans eklendi: {} {} (varyant: {})", saved.getCrossRefBrand(), saved.getCrossRefNumber(), variant.getId());
        return toResponse(saved);
    }

    @Override
    public List<CrossReferenceResponse> bulkCreate(String variantId, List<CrossReferenceRequest> requests) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + variantId));
        List<CrossReferenceResponse> responses = new ArrayList<>();
        for (CrossReferenceRequest request : requests) {
            CrossReference cr = CrossReference.builder()
                    .variant(variant)
                    .crossRefNumber(request.getCrossRefNumber())
                    .crossRefBrand(request.getCrossRefBrand())
                    .notes(request.getNotes())
                    .build();
            responses.add(toResponse(save(cr)));
        }
        log.info("{} adet capraz referans eklendi (varyant: {})", responses.size(), variantId);
        return responses;
    }

    @Override
    public void deleteCrossReference(String id) {
        CrossReference cr = findById(id)
                .orElseThrow(() -> new RuntimeException("Capraz referans bulunamadi: " + id));
        delete(cr);
        log.info("Capraz referans silindi: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CrossReferenceResponse> searchByCrossRefNumber(String q) {
        return dao.searchByCrossRefNumber(q).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private CrossReferenceResponse toResponse(CrossReference cr) {
        return CrossReferenceResponse.builder()
                .id(cr.getId())
                .variantId(cr.getVariant().getId())
                .crossRefNumber(cr.getCrossRefNumber())
                .crossRefBrand(cr.getCrossRefBrand())
                .notes(cr.getNotes())
                .build();
    }
}
