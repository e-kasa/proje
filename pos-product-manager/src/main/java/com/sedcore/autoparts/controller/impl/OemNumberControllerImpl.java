package com.sedcore.autoparts.controller.impl;

import com.sedcore.autoparts.controller.OemNumberController;
import com.sedcore.autoparts.model.OemNumberRequest;
import com.sedcore.autoparts.model.OemNumberResponse;
import com.sedcore.autoparts.service.OemNumberService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/oem-number")
public class OemNumberControllerImpl implements OemNumberController {

    private final OemNumberService oemNumberService;

    @Override
    @GetMapping("/variant/{variantId}")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> getByVariantId(@PathVariable String variantId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<OemNumberResponse>> createOemNumber(@RequestBody OemNumberRequest request) {
        try {
            OemNumberResponse response = oemNumberService.createOemNumber(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PostMapping("/bulk/{variantId}")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<OemNumberRequest> requests) {
        try {
            List<OemNumberResponse> responses = oemNumberService.bulkCreate(variantId, requests);
            return ResponseEntity.ok(ApiResponse.success(responses));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteOemNumber(@PathVariable String id) {
        try {
            oemNumberService.deleteOemNumber(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> searchByOemNumber(@RequestParam String q) {
        try {
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            throw ExceptionMapper.map(e);
      }
}
}
