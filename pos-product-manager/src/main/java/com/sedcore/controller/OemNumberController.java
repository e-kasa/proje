package com.sedcore.controller;

import com.sedcore.model.OemNumberRequest;
import com.sedcore.model.OemNumberResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface OemNumberController {

    ResponseEntity<ApiResponse<List<OemNumberResponse>>> getByVariantId(@PathVariable String variantId);

    ResponseEntity<ApiResponse<OemNumberResponse>> createOemNumber(@RequestBody OemNumberRequest request);

    ResponseEntity<ApiResponse<List<OemNumberResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<OemNumberRequest> requests);

    ResponseEntity<ApiResponse<Void>> deleteOemNumber(@PathVariable String id);

    ResponseEntity<ApiResponse<List<OemNumberResponse>>> searchByOemNumber(@RequestParam String q);
}
