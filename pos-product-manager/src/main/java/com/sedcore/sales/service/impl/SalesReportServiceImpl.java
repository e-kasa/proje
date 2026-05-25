package com.sedcore.sales.service.impl;

import com.sedcore.sales.entity.Sale;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.sales.model.CustomerSalesAnalysis;
import com.sedcore.sales.model.ProductSalesAnalysis;
import com.sedcore.sales.model.ProfitOverview;
import com.sedcore.sales.model.SalesSummary;
import com.sedcore.purchase.repository.PurchaseRepository;
import com.sedcore.sales.repository.SaleRepository;
import com.sedcore.inventory.repository.StockMovementRepository;
import com.sedcore.sales.service.SalesReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SalesReportServiceImpl implements SalesReportService {

    private final SaleRepository saleRepository;
    private final StockMovementRepository stockMovementRepository;
    private final PurchaseRepository purchaseRepository;

    @Override
    public SalesSummary getSalesSummary(LocalDateTime startDate, LocalDateTime endDate, String groupBy) {
        log.info("Satis ozeti: {} - {}, groupBy={}", startDate, endDate, groupBy);

        var allSales = (List<Sale>) saleRepository.findAll();
        var filtered = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .toList();

        var totalRevenue = filtered.stream()
                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        var totalPaid = filtered.stream()
                .map(s -> s.getPaidAmount() != null ? s.getPaidAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Vergi/iskonto ayrımı (Sprint 2026-05-25)
        var totalVat = filtered.stream()
                .map(s -> s.getTotalTax() != null ? s.getTotalTax() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        var totalOtv = filtered.stream()
                .map(s -> s.getTotalOtv() != null ? s.getTotalOtv() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        var totalDiscount = filtered.stream()
                .map(s -> s.getTotalDiscount() != null ? s.getTotalDiscount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        var avgOrder = !filtered.isEmpty()
                ? totalRevenue.divide(BigDecimal.valueOf(filtered.size()), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String pattern = "month".equalsIgnoreCase(groupBy) ? "yyyy-MM" : "yyyy-MM-dd";
        var df = DateTimeFormatter.ofPattern(pattern);

        var grouped = new TreeMap<String, List<Sale>>();
        for (var s : filtered) {
            grouped.computeIfAbsent(s.getSaleDate().format(df), k -> new ArrayList<>()).add(s);
        }

        var periodData = grouped.entrySet().stream()
                .map(e -> SalesSummary.PeriodData.builder()
                        .period(e.getKey())
                        .salesCount((long) e.getValue().size())
                        .revenue(e.getValue().stream()
                                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .paidAmount(e.getValue().stream()
                                .map(s -> s.getPaidAmount() != null ? s.getPaidAmount() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .vat(e.getValue().stream()
                                .map(s -> s.getTotalTax() != null ? s.getTotalTax() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .otv(e.getValue().stream()
                                .map(s -> s.getTotalOtv() != null ? s.getTotalOtv() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .build())
                .toList();

        return SalesSummary.builder()
                .totalSalesCount((long) filtered.size())
                .totalRevenue(totalRevenue)
                .averageOrderValue(avgOrder)
                .totalPaidAmount(totalPaid)
                .totalDebtAmount(totalRevenue.subtract(totalPaid))
                .totalVat(totalVat)
                .totalOtv(totalOtv)
                .totalDiscount(totalDiscount)
                .periodData(periodData)
                .build();
    }

    @Override
    public List<ProductSalesAnalysis> getProductSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit) {
        log.info("Urun satis analizi: {} - {}, limit={}", startDate, endDate, limit);

        var allMovements = (List<StockMovement>) stockMovementRepository.findAll();
        var saleMovements = allMovements.stream()
                .filter(m -> m.getMovementType() == StockMovementType.SALE_OUT)
                .filter(m -> m.getCreateTime() != null
                        && !toLocalDateTime(m.getCreateTime()).isBefore(startDate)
                        && !toLocalDateTime(m.getCreateTime()).isAfter(endDate))
                .toList();

        var byVariant = new HashMap<String, List<StockMovement>>();
        for (var m : saleMovements) {
            if (m.getVariant() != null) {
                byVariant.computeIfAbsent(m.getVariant().getId(), k -> new ArrayList<>()).add(m);
            }
        }

        return byVariant.entrySet().stream()
                .map(e -> {
                    var first = e.getValue().get(0);
                    int totalQty = e.getValue().stream()
                            .mapToInt(m -> m.getQuantity() != null ? m.getQuantity() : 0)
                            .sum();
                    var totalRev = e.getValue().stream()
                            .map(m -> {
                                var price = m.getUnitPrice() != null ? m.getUnitPrice() : BigDecimal.ZERO;
                                int qty = m.getQuantity() != null ? m.getQuantity() : 0;
                                return price.multiply(BigDecimal.valueOf(qty));
                            })
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    var avgPrice = totalQty > 0
                            ? totalRev.divide(BigDecimal.valueOf(totalQty), 2, RoundingMode.HALF_UP)
                            : BigDecimal.ZERO;
                    String productName = first.getVariant().getProduct() != null
                            ? first.getVariant().getProduct().getName() : "";

                    return ProductSalesAnalysis.builder()
                            .variantId(first.getVariant().getId())
                            .variantSku(first.getVariant().getSku())
                            .variantName(first.getVariant().getName())
                            .productName(productName)
                            .quantitySold(totalQty)
                            .totalRevenue(totalRev)
                            .averageUnitPrice(avgPrice)
                            .build();
                })
                .sorted(Comparator.<ProductSalesAnalysis, BigDecimal>comparing(ProductSalesAnalysis::totalRevenue).reversed())
                .limit(limit)
                .toList();
    }

    @Override
    public List<CustomerSalesAnalysis> getCustomerSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit) {
        log.info("Musteri satis analizi: {} - {}, limit={}", startDate, endDate, limit);

        var allSales = (List<Sale>) saleRepository.findAll();
        var filtered = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .filter(s -> s.getCustomer() != null)
                .toList();

        var byCustomer = new HashMap<String, List<Sale>>();
        for (var s : filtered) {
            byCustomer.computeIfAbsent(s.getCustomer().getId(), k -> new ArrayList<>()).add(s);
        }

        return byCustomer.entrySet().stream()
                .map(e -> {
                    var first = e.getValue().get(0);
                    var totalSpent = e.getValue().stream()
                            .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    var avgOrder = totalSpent.divide(
                            BigDecimal.valueOf(e.getValue().size()), 2, RoundingMode.HALF_UP);
                    var lastDate = e.getValue().stream()
                            .map(Sale::getSaleDate)
                            .max(Comparator.naturalOrder())
                            .orElse(null);
                    String custType = first.getCustomer().getCustomerType() != null
                            ? first.getCustomer().getCustomerType().name() : "INDIVIDUAL";

                    return CustomerSalesAnalysis.builder()
                            .customerId(first.getCustomer().getId())
                            .customerName(first.getCustomer().getName())
                            .customerType(custType)
                            .totalPurchases((long) e.getValue().size())
                            .totalSpent(totalSpent)
                            .averageOrderValue(avgOrder)
                            .lastPurchaseDate(lastDate)
                            .build();
                })
                .sorted(Comparator.<CustomerSalesAnalysis, BigDecimal>comparing(CustomerSalesAnalysis::totalSpent).reversed())
                .limit(limit)
                .toList();
    }

    @Override
    public ProfitOverview getProfitOverview(LocalDateTime startDate, LocalDateTime endDate) {
        log.info("Kar/zarar ozeti: {} - {}", startDate, endDate);

        // Satış ve stok hareketi verilerini paralel çek — CompletableFuture (Java 17 uyumlu)
        CompletableFuture<List<Sale>> salesFuture =
                CompletableFuture.supplyAsync(() -> (List<Sale>) saleRepository.findAll());
        CompletableFuture<List<StockMovement>> movementsFuture =
                CompletableFuture.supplyAsync(() -> (List<StockMovement>) stockMovementRepository.findAll());

        List<Sale> allSales;
        List<StockMovement> allMovements;
        try {
            allSales     = salesFuture.get();
            allMovements = movementsFuture.get();
        } catch (Exception e) {
            Thread.currentThread().interrupt();
            log.error("Paralel veri çekimi başarısız, sıralı çekime geçiliyor", e);
            allSales     = (List<Sale>) saleRepository.findAll();
            allMovements = (List<StockMovement>) stockMovementRepository.findAll();
        }

        var filteredSales = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .toList();

        var totalRevenue = filteredSales.stream()
                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        var totalCost = allMovements.stream()
                .filter(m -> m.getMovementType() == StockMovementType.SALE_OUT)
                .filter(m -> m.getCreateTime() != null
                        && !toLocalDateTime(m.getCreateTime()).isBefore(startDate)
                        && !toLocalDateTime(m.getCreateTime()).isAfter(endDate))
                .map(m -> {
                    var price = m.getUnitPrice() != null ? m.getUnitPrice() : BigDecimal.ZERO;
                    int qty = m.getQuantity() != null ? m.getQuantity() : 0;
                    return price.multiply(BigDecimal.valueOf(qty));
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        var grossProfit = totalRevenue.subtract(totalCost);
        var margin = totalRevenue.compareTo(BigDecimal.ZERO) > 0
                ? grossProfit.multiply(BigDecimal.valueOf(100)).divide(totalRevenue, 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return ProfitOverview.builder()
                .totalRevenue(totalRevenue)
                .totalCost(totalCost)
                .grossProfit(grossProfit)
                .profitMarginPercent(margin)
                .totalSalesCount((long) filteredSales.size())
                .totalPurchaseCount(0L)
                .build();
    }

    private LocalDateTime toLocalDateTime(Date date) {
        return date.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
    }
}
