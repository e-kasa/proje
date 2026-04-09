package com.sedcore.controller.impl;

import com.sedcore.controller.PartSearchController;
import com.sedcore.model.PartSearchResponse;
import com.sedcore.service.PartSearchService;
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
@RequestMapping("/api/part-search")
public class PartSearchControllerImpl implements PartSearchController {

    private final PartSearchService partSearchService;

    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<PartSearchResponse>>> searchParts(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year) {
        try {
            List<PartSearchResponse> results = partSearchService.searchParts(q, make, model, year);
            return ResponseEntity.ok(ApiResponse.success(results.size() + " sonuc bulundu", results));
        } catch (Exception e) {
            log.error("Parca aranirken hata: {}", e.getMessage());
            throw ExceptionMapper.map(e);
        }
    }
}
