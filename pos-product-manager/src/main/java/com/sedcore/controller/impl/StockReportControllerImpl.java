package com.sedcore.controller.impl;

import com.sedcore.model.reports.CriticalStockAlert;
import com.sedcore.model.reports.StockMovementSummary;
import com.sedcore.model.reports.StockValueSummary;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.StockReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/product/api/v1/reports/stock")
@RequiredArgsConstructor
@Slf4j
public class StockReportControllerImpl {

    private final StockReportService stockReportService;

    // GET /product/api/v1/reports/stock/value-summary
    @GetMapping("/value-summary")
    public ResponseEntity<ApiResponse<StockValueSummary>> getValueSummary() {
        try {
            return ResponseEntity.ok(ApiResponse.success(stockReportService.getStockValueSummary()));
        } catch (Exception e) {
            log.error("Stok deger ozeti hatasi: {}", e.getMessage());
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/movement-summary?startDate=...&endDate=...
    @GetMapping("/movement-summary")
    public ResponseEntity<ApiResponse<StockMovementSummary>> getMovementSummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(stockReportService.getMovementSummary(startDate, endDate)));
        } catch (Exception e) {
            log.error("Stok hareket ozeti hatasi: {}", e.getMessage());
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/critical-alerts
    @GetMapping("/critical-alerts")
    public ResponseEntity<ApiResponse<List<CriticalStockAlert>>> getCriticalAlerts() {
        try {
            return ResponseEntity.ok(ApiResponse.success(stockReportService.getCriticalAlerts()));
        } catch (Exception e) {
            log.error("Kritik stok alarmlari hatasi: {}", e.getMessage());
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/warehouse-breakdown?warehouseId=...
    @GetMapping("/warehouse-breakdown")
    public ResponseEntity<ApiResponse<StockValueSummary>> getWarehouseBreakdown(
            @RequestParam String warehouseId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(stockReportService.getWarehouseBreakdown(warehouseId)));
        } catch (Exception e) {
            log.error("Depo stok detayi hatasi: {}", e.getMessage());
            throw ExceptionMapper.map(e);
        }
    }
}
