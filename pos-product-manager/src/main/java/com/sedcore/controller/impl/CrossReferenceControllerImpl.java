package com.sedcore.controller.impl;

import com.sedcore.controller.CrossReferenceController;
import com.sedcore.model.CrossReferenceRequest;
import com.sedcore.model.CrossReferenceResponse;
import com.sedcore.service.CrossReferenceService;
import com.sedcore.se.ApiResponse;
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
            return ResponseEntity.ok(ApiResponse.success("Capraz referanslar getirildi", crossReferenceService.getByVariantId(variantId)));
        } catch (Exception e) {
            log.error("Capraz referanslar getirilirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<CrossReferenceResponse>> createCrossReference(@RequestBody CrossReferenceRequest request) {
        try {
            CrossReferenceResponse response = crossReferenceService.createCrossReference(request);
            return ResponseEntity.ok(ApiResponse.success("Capraz referans eklendi", response));
        } catch (Exception e) {
            log.error("Capraz referans eklenirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping("/bulk/{variantId}")
    public ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<CrossReferenceRequest> requests) {
        try {
            List<CrossReferenceResponse> responses = crossReferenceService.bulkCreate(variantId, requests);
            return ResponseEntity.ok(ApiResponse.success("Capraz referanslar toplu eklendi", responses));
        } catch (Exception e) {
            log.error("Capraz referanslar toplu eklenirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCrossReference(@PathVariable String id) {
        try {
            crossReferenceService.deleteCrossReference(id);
            return ResponseEntity.ok(ApiResponse.success("Capraz referans silindi", null));
        } catch (Exception e) {
            log.error("Capraz referans silinirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<CrossReferenceResponse>>> searchByCrossRefNumber(@RequestParam String q) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Arama sonuclari", crossReferenceService.searchByCrossRefNumber(q)));
        } catch (Exception e) {
            log.error("Capraz referans aranirken hata: {}", e);
            throw ExceptionMapper.map(e);
        }
    }
}
