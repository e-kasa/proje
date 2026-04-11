package com.sedcore.autoparts.controller;

import com.sedcore.autoparts.model.CrossReferenceRequest;
import com.sedcore.autoparts.model.CrossReferenceResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface CrossReferenceController {

    ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> getByVariantId(@PathVariable String variantId);

    ResponseEntity<ApiResponse<CrossReferenceResponse>> createCrossReference(@RequestBody CrossReferenceRequest request);

    ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<CrossReferenceRequest> requests);

    ResponseEntity<ApiResponse<Void>> deleteCrossReference(@PathVariable String id);

    ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> searchByCrossRefNumber(@RequestParam String q);
}
