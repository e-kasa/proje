package com.sedcore.service.impl;

import com.sedcore.entity.ProductRelationship;
import com.sedcore.enums.ProductRelationType;
import com.sedcore.model.ProductRelationshipRequest;
import com.sedcore.repository.ProductRelationshipRepository;
import com.sedcore.service.ProductRelationshipService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class ProductRelationshipServiceImpl extends BaseDbServiceImp<ProductRelationshipRepository, ProductRelationship> implements ProductRelationshipService {

    @Override
    @CacheEvict(value = "recommendations", allEntries = true)
    public ProductRelationship createRelationship(ProductRelationshipRequest request) {
        log.info("Ilişki oluşturuluyor | Source: {} | Target: {} | Type: {}",
                request.getSourceProductId(), request.getTargetProductId(), request.getRelationType());

        ProductRelationship relationship = ProductRelationship.builder()
                .sourceProductId(request.getSourceProductId())
                .targetProductId(request.getTargetProductId())
                .relationType(request.getRelationType())
                .weight(request.getWeight())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .createdBy(request.getCreatedBy())
                .build();

        return save(relationship);
    }

    @Override
    @CacheEvict(value = "recommendations", allEntries = true)
    public ProductRelationship updateRelationship(String id, ProductRelationshipRequest request) {
        ProductRelationship relationship = findById(id)
                .orElseThrow(() -> new RuntimeException("Ilişki bulunamadı: " + id));

        relationship.setRelationType(request.getRelationType());
        relationship.setWeight(request.getWeight());
        relationship.setIsActive(request.getIsActive());
        relationship.setUpdatedBy(request.getCreatedBy());

        return save(relationship);
    }

    @Override
    @CacheEvict(value = "recommendations", allEntries = true)
    public void deactivateRelationship(String id) {
        ProductRelationship relationship = findById(id)
                .orElseThrow(() -> new RuntimeException("Ilişki bulunamadı: " + id));

        relationship.setIsActive(false);
        save(relationship);
        log.info("Ilişki deaktif edildi: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductRelationship> getRelationshipsBySourceProduct(String sourceProductId) {
        return dao.findBySourceProductIdOrderByWeightDesc(sourceProductId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductRelationship> getRelationshipsBySourceProductAndType(
            String sourceProductId, ProductRelationType relationType) {
        return dao.findBySourceProductIdAndRelationType(sourceProductId, relationType);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductRelationship> getAllRelationships(Pageable pageable) {
        return dao.findAll(pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductRelationship> getRelationshipsByType(
            ProductRelationType relationType, Pageable pageable) {
        List<ProductRelationship> list = dao.findByRelationType(relationType);
        int start = (int) pageable.getOffset();
        int end = Math.min((start + pageable.getPageSize()), list.size());
        return new PageImpl<>(list.subList(start, end), pageable, list.size());
    }

    @Override
    @CacheEvict(value = "recommendations", allEntries = true)
    public List<ProductRelationship> bulkImportRelationships(List<ProductRelationshipRequest> requests) {
        log.info("Toplu ilişki import başlıyor | Count: {}", requests.size());

        List<ProductRelationship> relationships = requests.stream()
                .map(req -> ProductRelationship.builder()
                        .sourceProductId(req.getSourceProductId())
                        .targetProductId(req.getTargetProductId())
                        .relationType(req.getRelationType())
                        .weight(req.getWeight())
                        .isActive(req.getIsActive() != null ? req.getIsActive() : true)
                        .createdBy(req.getCreatedBy())
                        .build())
                .collect(Collectors.toList());

        List<ProductRelationship> saved = new ArrayList<>();
        dao.saveAll(relationships).forEach(saved::add);
        log.info("Toplu import tamamlandı | Count: {}", saved.size());
        return saved;
    }

    @Override
    public Class<?> getDTOClassForService() {
        return null;
    }
}
