package com.sedcore.controller.impl;

import com.sedcore.model.reports.CriticalStockAlert;
import com.sedcore.model.reports.StockMovementSummary;
import com.sedcore.model.reports.StockValueSummary;
import com.towpen.base.exceptions.ApiResponse;
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
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error([^;]+);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/movement-summary?startDate=...&endDate=...
    @GetMapping("/movement-summary")
    public ResponseEntity<ApiResponse<StockMovementSummary>> getMovementSummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error([^;]+);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/critical-alerts
    @GetMapping("/critical-alerts")
    public ResponseEntity<ApiResponse<List<CriticalStockAlert>>> getCriticalAlerts() {
        try {
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error([^;]+);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/stock/warehouse-breakdown?warehouseId=...
    @GetMapping("/warehouse-breakdown")
    public ResponseEntity<ApiResponse<StockValueSummary>> getWarehouseBreakdown(
            @RequestParam String warehouseId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error([^;]+);
            throw ExceptionMapper.map(e);
      }
}
}
