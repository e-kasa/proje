package com.sedcore.controller.impl;

import com.sedcore.entity.StockMovement;
import com.sedcore.model.StockCountRequest;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.impl.StockCountServiceIntegrated;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Stok Sayım ve Düzeltme Controller
 *
 * POST /product/api/v1/stock-counts
 *
 * Fiili sayım sonuçlarını alır, inventory_view ile karşılaştırır
 * ve fark varsa ADJUSTMENT_IN / ADJUSTMENT_OUT hareketi yazar.
 */
@RestController
@RequestMapping("/product/api/v1/stock-counts")
@RequiredArgsConstructor
@Slf4j
public class StockCountControllerImpl {

    private final StockCountServiceIntegrated stockCountService;

    // POST /product/api/v1/stock-counts
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> processCount(
            @Valid @RequestBody StockCountRequest request) {
        try {
            List<StockMovement> adjustments = stockCountService.processStockCount(request);

            Map<String, Object> result = new HashMap<>();
            result.put("storeId", request.getStoreId());
            result.put("warehouseId", request.getWarehouseId());
            result.put("countedItems", request.getItems().size());
            result.put("adjustmentCount", adjustments.size());
            result.put("adjustments", adjustments.stream()
                    .map(this::toMap)
                    .collect(Collectors.toList()));

            log.info("Stok sayimi islendi - Magaza: {}, Depo: {}, Duzeltme: {}",
                    request.getStoreId(), request.getWarehouseId(), adjustments.size());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (Exception e) {
            log.error("Stok sayim hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Sayim islemi basarisiz: " + e.getMessage()));
        }
    }

    private Map<String, Object> toMap(StockMovement m) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", m.getId());
        map.put("movementType", m.getMovementType());
        map.put("quantity", m.getQuantity());
        map.put("storeId", m.getStoreId());
        map.put("warehouseId", m.getWarehouseId());
        if (m.getVariant() != null) {
            map.put("variantId", m.getVariant().getId());
            map.put("variantSku", m.getVariant().getSku());
        }
        return map;
    }
}
