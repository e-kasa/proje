package com.sedcore.inventory.controller.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.exception.BusinessException;
import com.sedcore.inventory.entity.StockLevel;
import com.sedcore.inventory.service.StockLevelService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * StockLevel REST Controller
 *
 * Flutter URL'leri (api-manager üzerinden):
 *   GET  product/api/v1/stock-levels                         → tüm lokasyon stoklarını listele
 *   GET  product/api/v1/stock-levels?variantId={id}          → varyantın tüm lokasyonlardaki stoku
 *   GET  product/api/v1/stock-levels?locationId={code}       → lokasyonun tüm ürün stoklarını
 *   GET  product/api/v1/stock-levels/{variantId}/{locationId} → tek kayıt
 *   PUT  product/api/v1/stock-levels/{variantId}/{locationId}/min-quantity → alarm eşiği güncelle
 *   GET  product/api/v1/stock-levels/critical                → kritik stok listesi
 *   GET  product/api/v1/stock-levels/total/{variantId}       → varyant toplam stoku
 */
@RestController
@RequestMapping("/api/v1/stock-levels")
@RequiredArgsConstructor
public class StockLevelControllerImpl {

    private final StockLevelService stockLevelService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String variantId,
            @RequestParam(required = false) String locationId) {

        List<StockLevel> levels;
        if (variantId != null && !variantId.isBlank()) {
            levels = stockLevelService.getByVariant(variantId);
        } else if (locationId != null && !locationId.isBlank()) {
            levels = stockLevelService.getByLocation(locationId);
        } else {
            // Tüm lokasyonlar — Hibernate filter otomatik company izolasyonu sağlar
            levels = stockLevelService.getByLocation(null);
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", levels.stream().map(this::toMap).collect(Collectors.toList())
        ));
    }

    @GetMapping("/{variantId}/{locationId}")
    public ResponseEntity<Map<String, Object>> getOne(
            @PathVariable String variantId,
            @PathVariable String locationId) {

        Integer qty = stockLevelService.getQuantity(variantId, locationId);
        List<StockLevel> levels = stockLevelService.getByVariant(variantId);
        StockLevel sl = levels.stream()
                .filter(s -> locationId.equals(s.getLocationId()))
                .findFirst()
                .orElse(null);

        if (sl == null) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "data", Map.of("variantId", variantId, "locationId", locationId,
                            "quantity", 0, "minQuantity", 5)
            ));
        }
        return ResponseEntity.ok(Map.of("success", true, "data", toMap(sl)));
    }

    @GetMapping("/critical")
    public ResponseEntity<Map<String, Object>> critical() {
        String companyCode = CompanyContext.get();
        List<StockLevel> levels = stockLevelService.getCriticalStocks(companyCode);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", levels.stream().map(this::toMap).collect(Collectors.toList())
        ));
    }

    @GetMapping("/total/{variantId}")
    public ResponseEntity<Map<String, Object>> total(@PathVariable String variantId) {
        int total = stockLevelService.getTotalQuantity(variantId);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("variantId", variantId, "totalQuantity", total)
        ));
    }

    @PutMapping("/{variantId}/{locationId}/min-quantity")
    public ResponseEntity<Map<String, Object>> updateMinQuantity(
            @PathVariable String variantId,
            @PathVariable String locationId,
            @RequestBody Map<String, Integer> body) {

        Integer minQty = body.get("minQuantity");
        if (minQty == null || minQty < 0) {
            throw new BusinessException("minQuantity geçersiz");
        }
        StockLevel updated = stockLevelService.updateMinQuantity(variantId, locationId, minQty);
        return ResponseEntity.ok(Map.of("success", true, "data", toMap(updated)));
    }

    private Map<String, Object> toMap(StockLevel sl) {
        return Map.of(
                "id", sl.getId() != null ? sl.getId() : "",
                "variantId", sl.getVariantId(),
                "locationId", sl.getLocationId(),
                "locationType", sl.getLocationType(),
                "quantity", sl.getQuantity() != null ? sl.getQuantity() : 0,
                "minQuantity", sl.getMinQuantity() != null ? sl.getMinQuantity() : 5,
                "isCritical", (sl.getQuantity() != null ? sl.getQuantity() : 0)
                        <= (sl.getMinQuantity() != null ? sl.getMinQuantity() : 5)
        );
    }
}
