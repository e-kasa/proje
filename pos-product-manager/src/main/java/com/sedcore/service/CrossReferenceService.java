package com.sedcore.service;

import com.sedcore.entity.CrossReference;
import com.sedcore.model.CrossReferenceRequest;
import com.sedcore.model.CrossReferenceResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface CrossReferenceService extends BaseDbService<CrossReference> {

    List<CrossReferenceResponse> getByVariantId(String variantId);

    CrossReferenceResponse createCrossReference(CrossReferenceRequest request);

    List<CrossReferenceResponse> bulkCreate(String variantId, List<CrossReferenceRequest> requests);

    void deleteCrossReference(String id);

    List<CrossReferenceResponse> searchByCrossRefNumber(String q);
}
