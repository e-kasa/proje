package com.sedcore.inventory.controller.impl;

import com.sedcore.inventory.model.CriticalStockAlert;
import com.sedcore.inventory.model.StockMovementSummary;
import com.sedcore.inventory.model.StockValueSummary;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.inventory.service.StockReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/reports/stock")
@RequiredArgsConstructor
@Slf4j
public class StockReportControllerImpl {

    private final StockReportService stockReportService;

    // GET /product/api/v1/reports/stock/value-summary
    @GetMapping("/value-summary")
    public ResponseEntity<ApiResponse<StockValueSummary>> getValueSummary() {
        try {
            StockValueSummary summary = stockReportService.getStockValueSummary();
            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/movement-summary?startDate=...&endDate=...
    @GetMapping("/movement-summary")
    public ResponseEntity<ApiResponse<StockMovementSummary>> getMovementSummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            StockMovementSummary summary = stockReportService.getMovementSummary(startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/critical-alerts
    @GetMapping("/critical-alerts")
    public ResponseEntity<ApiResponse<List<CriticalStockAlert>>> getCriticalAlerts() {
        try {
            List<CriticalStockAlert> alerts = stockReportService.getCriticalAlerts();
            return ResponseEntity.ok(ApiResponse.success(alerts));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/warehouse-breakdown?locationId=...
    @GetMapping("/warehouse-breakdown")
    public ResponseEntity<ApiResponse<StockValueSummary>> getWarehouseBreakdown(
            @RequestParam String locationId) {
        try {
            StockValueSummary summary = stockReportService.getWarehouseBreakdown(locationId);
            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
      }
}
}
