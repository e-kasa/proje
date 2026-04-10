package com.sedcore.controller.impl;

import com.sedcore.controller.CrossReferenceController;
import com.sedcore.model.CrossReferenceRequest;
import com.sedcore.model.CrossReferenceResponse;
import com.sedcore.service.CrossReferenceService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/cross-reference")
public class CrossReferenceControllerImpl implements CrossReferenceController {

    private final CrossReferenceService crossReferenceService;

    @Override
    @GetMapping("/variant/{variantId}")
    public ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> getByVariantId(@PathVariable String variantId) {
        try {
            List<CrossReferenceResponse> responses = crossReferenceService.getByVariantId(variantId);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<CrossReferenceResponse>> createCrossReference(@RequestBody CrossReferenceRequest request) {
        try {
            CrossReferenceResponse response = crossReferenceService.createCrossReference(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping("/bulk/{variantId}")
    public ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<CrossReferenceRequest> requests) {
        try {
            List<CrossReferenceResponse> responses = crossReferenceService.bulkCreate(variantId, requests);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCrossReference(@PathVariable String id) {
        try {
            crossReferenceService.deleteCrossReference(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> searchByCrossRefNumber(@RequestParam String q) {
        try {
            List<CrossReferenceResponse> responses = crossReferenceService.searchByCrossRefNumber(q);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }
}
