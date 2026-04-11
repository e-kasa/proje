package com.sedcore.report.controller.impl;

import com.sedcore.report.service.StatsService;
import com.sedcore.common.util.ExceptionMapper;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * GET /product/api/v1/reports/dashboard
 * Flutter report_service.dart: getDashboardStats()
 */
@RestController
@RequestMapping("api/v1/reports")
@RequiredArgsConstructor
@Slf4j
public class ReportsDashboardControllerImpl {

    private final StatsService statsService;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboard() {
        try {
            var overview = statsService.getOverview();
            Map<String, Object> dashboard = Map.of(
                    "totalRevenue",        overview.getTotalRevenue(),
                    "todayRevenue",        overview.getTodayRevenue(),
                    "monthRevenue",        overview.getMonthRevenue(),
                    "revenueChangePercent",overview.getRevenueChangePercent(),
                    "totalOrders",         overview.getTotalOrders(),
                    "pendingOrders",       overview.getPendingOrders(),
                    "completedOrders",     overview.getCompletedOrders(),
                    "totalCustomers",      overview.getTotalCustomers(),
                    "activeProducts",      overview.getActiveProducts(),
                    "outOfStockProducts",  overview.getOutOfStockProducts()
            );
            return ResponseEntity.ok(ApiResponse.success(dashboard));
        } catch (Exception e) {
            log.error("Dashboard rapor hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
