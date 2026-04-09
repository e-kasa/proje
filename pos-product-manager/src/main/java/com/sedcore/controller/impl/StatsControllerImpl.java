package com.sedcore.controller.impl;

import com.sedcore.model.stats.*;
import com.towpen.base.exceptions.ApiResponse;

 import com.sedcore.service.StatsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;

/**
 * E-ticaret istatistik endpoint'leri.
 *
 * Tüm endpoint'ler /product/api/v1/stats/** altındadır.
 * JWT ile korumalıdır; sadece yetkili kullanıcılar erişebilir.
 * Hibernate company filtresi otomatik aktif olur (CompanyHibernateFilterActivator).
 *
 * Admin dashboard ve raporlama sayfaları bu endpoint'leri kullanır.
 */
@Slf4j
@RestController
@RequestMapping("api/v1/stats")
@RequiredArgsConstructor
public class StatsControllerImpl {

    private final StatsService statsService;

    /**
     * KPI özet kartları.
     * GET /product/api/v1/stats/overview
     */
    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<StatsOverviewResponse>> getOverview() {
        return ResponseEntity.ok(ApiResponse.success(statsService.getOverview()));
    }

    /**
     * Gelir ve sipariş trendi grafiği.
     * GET /product/api/v1/stats/revenue?period=monthly
     *
     * @param period daily | weekly | monthly | yearly (varsayılan: monthly)
     */
    @GetMapping("/revenue")
    public ResponseEntity<ApiResponse<RevenueDataResponse>> getRevenueTrend(
            @RequestParam(defaultValue = "monthly") String period) {
        return ResponseEntity.ok(ApiResponse.success(statsService.getRevenueTrend(period)));
    }

    /**
     * En çok satan ürünler.
     * GET /product/api/v1/stats/top-products?limit=10
     */
    @GetMapping("/top-products")
    public ResponseEntity<ApiResponse<List<TopProductResponse>>> getTopProducts(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(ApiResponse.success(statsService.getTopProducts(limit)));
    }

    /**
     * Sipariş durumu dağılımı (donut chart).
     * GET /product/api/v1/stats/order-status
     */
    @GetMapping("/order-status")
    public ResponseEntity<ApiResponse<OrderStatusDistribution>> getOrderStatus() {
        return ResponseEntity.ok(ApiResponse.success(statsService.getOrderStatusDistribution()}
}
