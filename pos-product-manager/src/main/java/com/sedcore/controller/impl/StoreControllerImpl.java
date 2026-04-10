package com.sedcore.controller.impl;

import com.sedcore.entity.Store;
import com.sedcore.service.StoreService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/stores")
@RequiredArgsConstructor
@Slf4j
public class StoreControllerImpl {

    private final StoreService storeService;

    // GET /api/v1/stores?isActive=true
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) Boolean isActive
    ) {
        try {
            List<Store> stores = (isActive != null && !isActive)
                    ? (List<Store>) storeService.findAll()
                    : storeService.listActive();

            return ResponseEntity.ok(ApiResponse.success(
                    stores.stream().map(this::toMap).collect(Collectors.toList())));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /api/v1/stores/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            Store store = storeService.findById(id)
                    .orElseThrow(() -> new RuntimeException("Magaza bulunamadi: " + id));
            return ResponseEntity.ok(ApiResponse.success(toMap(store)));
        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    private Map<String, Object> toMap(Store s) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", s.getId());
        m.put("code", s.getCode());
        m.put("name", s.getName());
        m.put("address", s.getAddress());
        m.put("phone", s.getPhone());
        m.put("isActive", s.getIsActive());
        return m;
    }
}
