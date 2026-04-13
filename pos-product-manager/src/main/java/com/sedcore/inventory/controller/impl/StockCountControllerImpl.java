package com.sedcore.inventory.controller.impl;

import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.inventory.model.StockCountRequest;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.inventory.service.impl.StockCountServiceIntegrated;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

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
@RequestMapping("/api/v1/stock-counts")
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
            result.put("locationId", request.getLocationId());
            result.put("locationType", request.getLocationType());
            result.put("countedItems", request.getItems().size());
            result.put("adjustmentCount", adjustments.size());
            result.put("adjustments", adjustments.stream()
                    .map(this::toMap)
                    .collect(Collectors.toList()));

            log.info("Stok sayimi islendi - Lokasyon: {}, Duzeltme: {}",
                    request.getLocationId(), adjustments.size());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Stok sayim hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    private Map<String, Object> toMap(StockMovement m) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", m.getId());
        map.put("movementType", m.getMovementType());
        map.put("quantity", m.getQuantity());
        map.put("locationId", m.getLocationId());
        map.put("locationType", m.getLocationType());
        if (m.getVariant() != null) {
            map.put("variantId", m.getVariant().getId());
            map.put("variantSku", m.getVariant().getSku());
        }
        return map;
    }
}
