package com.sedcore.report.model;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

/**
 * E-ticaret özet istatistikleri.
 * Her firma (company_code) kendi verisini görür — Hibernate filtresi aktif.
 */
@Data
@Builder
public class StatsOverviewResponse {

    // ── Gelir ──────────────────────────────────────────────
    /** Toplam gelir (tüm zamanlar) */
    private BigDecimal totalRevenue;
    /** Bugünkü gelir */
    private BigDecimal todayRevenue;
    /** Bu ayki gelir */
    private BigDecimal monthRevenue;
    /** Geçen aya göre değişim yüzdesi (pozitif = artış) */
    private Double revenueChangePercent;

    // ── Sipariş ────────────────────────────────────────────
    /** Toplam sipariş sayısı */
    private Long totalOrders;
    /** Bekleyen siparişler */
    private Long pendingOrders;
    /** Tamamlanan siparişler */
    private Long completedOrders;
    /** İptal edilen siparişler */
    private Long cancelledOrders;
    /** Bu ayki sipariş sayısı */
    private Long monthOrders;
    /** Geçen aya göre sipariş değişim yüzdesi */
    private Double ordersChangePercent;

    // ── Müşteri ────────────────────────────────────────────
    /** Toplam benzersiz müşteri */
    private Long totalCustomers;
    /** Bu ay yeni kayıt olan müşteriler */
    private Long newCustomers;
    /** Geçen aya göre müşteri büyüme yüzdesi */
    private Double customersChangePercent;

    // ── Ürün ───────────────────────────────────────────────
    /** Aktif ürün sayısı */
    private Long activeProducts;
    /** Stok tükenen ürün sayısı */
    private Long outOfStockProducts;

    // ── Ortalamalar ────────────────────────────────────────
    /** Ortalama sipariş değeri */
    private BigDecimal averageOrderValue;
    /** Dönüşüm oranı yüzdesi */
    private Double conversionRate;
}
