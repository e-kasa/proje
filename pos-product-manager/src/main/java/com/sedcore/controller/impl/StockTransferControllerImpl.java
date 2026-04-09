package com.sedcore.controller.impl;

import com.sedcore.entity.StockTransfer;
import com.sedcore.model.StockTransferRequest;
import com.sedcore.repository.StockTransferRepository;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.impl.StockTransferServiceIntegrated;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/stock-transfers")
@RequiredArgsConstructor
@Slf4j
public class StockTransferControllerImpl {

    private final StockTransferRepository stockTransferRepository;
    private final StockTransferServiceIntegrated transferService;

    // GET /product/api/v1/stock-transfers
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String fromStoreId,
            @RequestParam(required = false) String toStoreId
    ) {
        try {
            List<StockTransfer> transfers;
            if (fromStoreId != null) {
                transfers = stockTransferRepository.findByFromStoreId(fromStoreId);
            } else if (toStoreId != null) {
                transfers = stockTransferRepository.findByToStoreId(toStoreId);
            } else {
                transfers = (List<StockTransfer>) stockTransferRepository.findAll();
            }
            var result = transfers.stream().map(this::toMap).collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (Exception e) {
            log.error("Transfer listesi hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Transfer listesi alinamadi: " + e.getMessage()));
        }
    }

    // GET /product/api/v1/stock-transfers/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            StockTransfer transfer = stockTransferRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Transfer bulunamadi: " + id));
            return ResponseEntity.ok(ApiResponse.success(toMap(transfer)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // POST /product/api/v1/stock-transfers
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(
            @Valid @RequestBody StockTransferRequest request) {
        try {
            StockTransfer transfer = transferService.createTransfer(request);
            log.info("Transfer tamamlandi: ID={}, {} -> {}",
                    transfer.getId(), transfer.getFromWarehouseId(), transfer.getToWarehouseId());
            return ResponseEntity.ok(ApiResponse.success(toMap(transfer)));
        } catch (Exception e) {
            log.error("Transfer hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Transfer yapilamadi: " + e.getMessage()));
        }
    }

    private Map<String, Object> toMap(StockTransfer t) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", t.getId());
        m.put("fromStoreId", t.getFromStoreId());
        m.put("fromWarehouseId", t.getFromWarehouseId());
        m.put("toStoreId", t.getToStoreId());
        m.put("toWarehouseId", t.getToWarehouseId());
        m.put("companyCode", t.getCompanyCode());
        if (t.getMovements() != null) {
            m.put("movementCount", t.getMovements().size());
        }
        return m;
    }
}
