package com.sedcore.autoparts.service;

import com.sedcore.autoparts.entity.OemNumber;
import com.sedcore.autoparts.model.OemNumberRequest;
import com.sedcore.autoparts.model.OemNumberResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface OemNumberService extends BaseDbService<OemNumber> {

    List<OemNumberResponse> getByVariantId(String variantId);

    OemNumberResponse createOemNumber(OemNumberRequest request);

    List<OemNumberResponse> bulkCreate(String variantId, List<OemNumberRequest> requests);

    void deleteOemNumber(String id);

    List<OemNumberResponse> searchByOemNumber(String q);
}
