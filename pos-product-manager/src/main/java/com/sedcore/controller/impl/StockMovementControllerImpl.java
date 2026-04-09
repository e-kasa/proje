package com.sedcore.controller.impl;

import com.sedcore.context.CompanyContext;
import com.sedcore.entity.ProductVariant;
import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.StockMovementService;
import com.sedcore.util.EntityAuditHelper;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/product/api/v1/stock-movements")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Stock Movements", description = "Stock movement tracking endpoints")
@SecurityRequirement(name = "Bearer Authentication")
public class StockMovementControllerImpl {

    private final StockMovementRepository stockMovementRepository;
    private final ProductVariantRepository variantRepository;
    private final StockMovementService stockMovementService;
    private final EntityAuditHelper entityAuditHelper;

    // GET /product/api/v1/stock-movements
    @GetMapping
    @Operation(summary = "List stock movements", description = "Retrieves stock movements with filters")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Movements retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @Parameter(description = "Product variant ID")
            @RequestParam(required = false) String variantId,
            @Parameter(description = "Store ID filter")
            @RequestParam(required = false) String storeId,
            @Parameter(description = "Movement type filter (SALE_OUT, PURCHASE_IN, etc.)")
            @RequestParam(required = false) String movementType
    ) {
        try {
            final String companyCode = CompanyContext.get();
            List<StockMovement> movements;
            if (variantId != null && storeId != null) {
                movements = stockMovementRepository.findByVariantIdAndStoreId(variantId, storeId, companyCode);
            } else if (variantId != null) {
                movements = stockMovementRepository.findByVariantId(variantId, companyCode);
            } else {
                movements = (List<StockMovement>)stockMovementService.findAll();
            }
            var filtered = movements.stream()
                .filter(m -> movementType == null || movementType.equals(m.getMovementType().name()))
                .map(this::toMap)
                .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(filtered));
        } catch (Exception e) {
            log.error("Stok hareketi listesi hatası: {}", e.getMessage());
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
    }

    // GET /product/api/v1/stock-movements/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            var movement = stockMovementRepository.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            return ResponseEntity.ok(ApiResponse.success(toMap(movement)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Stok hareketi getirme hatası: {}", e.getMessage());
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
    }

    // POST /product/api/v1/stock-movements  (manual adjustment)
    @PostMapping
    @Operation(summary = "Create stock movement", description = "Records a manual stock movement (adjustment, transfer, etc.)")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Movement created"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid movement data")
    })
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@Valid @RequestBody StockMovementRequest dto) {
        try {
            // Implementation will go here
            ProductVariant variant = variantRepository.findById(dto.getVariantId())
                .orElseThrow(() -> new RuntimeException("Ürün varyantı bulunamadı: " + dto.getVariantId()));

            StockMovement movement = StockMovement.builder()
                .variant(variant)
                .storeId(dto.getStoreId())
                .warehouseId(dto.getWarehouseId())
                .movementType(StockMovementType.valueOf(dto.getMovementType()))
                .quantity(dto.getQuantity())
                .build();

            entityAuditHelper.prepare(movement);
            movement = stockMovementRepository.save(movement);
            log.info("Stok hareketi oluşturuldu: Variant={}, Tip={}, Miktar={}",
                variant.getSku(), movement.getMovementType(), movement.getQuantity());
            return ResponseEntity.ok(ApiResponse.success(toMap(movement)));
        } catch (IllegalArgumentException e) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        } catch (Exception e) {
            log.error("Stok hareketi oluşturma hatası: {}", e.getMessage());
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
    }

    // GET /product/api/v1/stock-movements/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            List<StockMovement> all = (List<StockMovement>)stockMovementRepository.findAll();
            Map<String, Object> s = new HashMap<>();
            s.put("totalMovements", all.size());
            s.put("inMovements", all.stream()
                .filter(m -> m.getMovementType().name().endsWith("_IN")).count());
            s.put("outMovements", all.stream()
                .filter(m -> m.getMovementType().name().endsWith("_OUT")).count());
            return ResponseEntity.ok(ApiResponse.success(s));
        } catch (Exception e) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }
    }

    private Map<String, Object> toMap(StockMovement m) {
        Map<String, Object> map = new HashMap<>();
        map.put("id",           m.getId());
        map.put("storeId",      m.getStoreId());
        map.put("warehouseId",  m.getWarehouseId());
        map.put("movementType", m.getMovementType());
        map.put("quantity",     m.getQuantity());
        map.put("unitPrice",    m.getUnitPrice());
        map.put("companyCode",  m.getCompanyCode());
        map.put("createTime",   m.getCreateTime());  // Hareket tarihi (UI için)
        map.put("createUser",   m.getCreateUser());

        if (m.getVariant() != null) {
            map.put("variantId",   m.getVariant().getId());
            map.put("variantSku",  m.getVariant().getSku());
            map.put("variantName", m.getVariant().getName());
            if (m.getVariant().getProduct() != null) {
                map.put("productName", m.getVariant().getProduct().getName());
                map.put("productId",   m.getVariant().getProduct().getId());
            }
        }
        if (m.getSale() != null) {
            map.put("saleId",     m.getSale().getId());
            map.put("saleNumber", m.getSale().getSaleNumber());
        }
        if (m.getPurchase() != null) {
            map.put("purchaseId",     m.getPurchase().getId());
            map.put("purchaseNumber", m.getPurchase().getInvoiceNumber());
        }
        if (m.getTransfer() != null) {
            map.put("transferId", m.getTransfer().getId());
        }
        return map;
    }

    @Data
    static class StockMovementRequest {
        @NotBlank
        private String variantId;
        @NotBlank
        private String storeId;
        @NotBlank
        private String warehouseId;
        @NotBlank
        private String movementType;
        @NotNull
        private Integer quantity;
    }
}
