package com.sedcore.service;

import com.sedcore.entity.ProductRelationship;
import com.sedcore.enums.ProductRelationType;
import com.sedcore.model.ProductRelationshipRequest;
import com.towpen.base.security.BaseDbService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface ProductRelationshipService extends BaseDbService<ProductRelationship> {

    ProductRelationship createRelationship(@Valid ProductRelationshipRequest request);

    ProductRelationship updateRelationship(String id, @Valid ProductRelationshipRequest request);

    void deactivateRelationship(String id);

    List<ProductRelationship> getRelationshipsBySourceProduct(String sourceProductId);

    List<ProductRelationship> getRelationshipsBySourceProductAndType(
            String sourceProductId, ProductRelationType relationType);

    Page<ProductRelationship> getAllRelationships(Pageable pageable);

    Page<ProductRelationship> getRelationshipsByType(ProductRelationType relationType, Pageable pageable);

    List<ProductRelationship> bulkImportRelationships(List<ProductRelationshipRequest> requests);
}
