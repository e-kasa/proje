package com.sedcore.controller.impl;

import com.sedcore.entity.Warehouse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.WarehouseService;
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
@RequestMapping("api/v1/warehouses")
@RequiredArgsConstructor
@Slf4j
public class WarehouseControllerImpl {

    private final WarehouseService warehouseService;

    // GET /api/v1/warehouses?storeCode=STORE-01&isActive=true
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String storeCode,
            @RequestParam(required = false) Boolean isActive
    ) {
        try {
            List<Warehouse> warehouses;
            if (storeCode != null) {
                warehouses = warehouseService.listByStore(storeCode);
            } else if (isActive != null && !isActive) {
                warehouses = (List<Warehouse>) warehouseService.findAll();
            } else {
                warehouses = warehouseService.listActive();
            }
            return ResponseEntity.ok(ApiResponse.success(
                    warehouses.stream().map(this::toMap).collect(Collectors.toList())));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /api/v1/warehouses/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            Warehouse wh = warehouseService.findById(id)
                    .orElseThrow(() -> new RuntimeException("Depo bulunamadi: " + id));
            return ResponseEntity.ok(ApiResponse.success(toMap(wh)));
        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    private Map<String, Object> toMap(Warehouse w) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", w.getId());
        m.put("code", w.getCode());
        m.put("name", w.getName());
        m.put("storeCode", w.getStoreCode());
        m.put("address", w.getAddress());
        m.put("isActive", w.getIsActive());
        return m;
    }
}
