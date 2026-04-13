package com.sedcore.inventory.controller.impl;

import com.sedcore.inventory.entity.StockTransfer;
import com.sedcore.inventory.model.StockTransferRequest;
import com.sedcore.inventory.repository.StockTransferRepository;
import com.sedcore.inventory.service.impl.StockTransferServiceIntegrated;
import com.towpen.base.exceptions.ApiResponse;
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

@RestController
@RequestMapping("/api/v1/stock-transfers")
@RequiredArgsConstructor
@Slf4j
public class StockTransferControllerImpl {

    private final StockTransferRepository stockTransferRepository;
    private final StockTransferServiceIntegrated transferService;

    // GET /product/api/v1/stock-transfers
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String fromLocationId,
            @RequestParam(required = false) String toLocationId
    ) {
        try {
            List<StockTransfer> transfers;
            if (fromLocationId != null) {
                transfers = stockTransferRepository.findByFromLocationId(fromLocationId);
            } else if (toLocationId != null) {
                transfers = stockTransferRepository.findByToLocationId(toLocationId);
            } else {
                transfers = (List<StockTransfer>) stockTransferRepository.findAll();
            }
            var result = transfers.stream().map(this::toMap).collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Transfer listesi hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/stock-transfers/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            StockTransfer transfer = stockTransferRepository.findById(id)
                    .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            return ResponseEntity.ok(ApiResponse.success(toMap(transfer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/v1/stock-transfers
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(
            @Valid @RequestBody StockTransferRequest request) {
        try {
            StockTransfer transfer = transferService.createTransfer(request);
            log.info("Transfer tamamlandi: ID={}, {} -> {}",
                    transfer.getId(), transfer.getFromLocationId(), transfer.getToLocationId());
            return ResponseEntity.ok(ApiResponse.success(toMap(transfer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Transfer hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    private Map<String, Object> toMap(StockTransfer t) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", t.getId());
        m.put("fromLocationId", t.getFromLocationId());
        m.put("fromLocationType", t.getFromLocationType());
        m.put("toLocationId", t.getToLocationId());
        m.put("toLocationType", t.getToLocationType());
        m.put("companyCode", t.getCompanyCode());
        if (t.getMovements() != null) {
            m.put("movementCount", t.getMovements().size());
        }
        return m;
    }
}
