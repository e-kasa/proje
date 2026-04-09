package com.sedcore.controller.impl;

import com.sedcore.model.reports.CustomerSalesAnalysis;
import com.sedcore.model.reports.ProductSalesAnalysis;
import com.sedcore.model.reports.ProfitOverview;
import com.sedcore.model.reports.SalesSummary;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.SalesReportService;
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
@RequestMapping("api/v1/reports/sales")
@RequiredArgsConstructor
@Slf4j
public class SalesReportControllerImpl {

    private final SalesReportService salesReportService;

    // GET /product/api/v1/reports/sales/summary
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<SalesSummary>> getSalesSummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "day") String groupBy) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
        } catch (Exception e) {
            log.error("Satis ozeti hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/sales/by-product
    @GetMapping("/by-product")
    public ResponseEntity<ApiResponse<List<ProductSalesAnalysis>>> getByProduct(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "20") int limit) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
        } catch (Exception e) {
            log.error("Urun satis analizi hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/sales/by-customer
    @GetMapping("/by-customer")
    public ResponseEntity<ApiResponse<List<CustomerSalesAnalysis>>> getByCustomer(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "20") int limit) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
        } catch (Exception e) {
            log.error("Musteri satis analizi hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/reports/sales/profit-overview
    @GetMapping("/profit-overview")
    public ResponseEntity<ApiResponse<ProfitOverview>> getProfitOverview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
        } catch (Exception e) {
            log.error("Kar/zarar ozeti hatasi: {}", e);
            throw ExceptionMapper.map(e);
      