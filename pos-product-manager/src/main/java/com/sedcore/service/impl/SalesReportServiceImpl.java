package com.sedcore.service.impl;

import com.sedcore.entity.Sale;
import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.reports.CustomerSalesAnalysis;
import com.sedcore.model.reports.ProductSalesAnalysis;
import com.sedcore.model.reports.ProfitOverview;
import com.sedcore.model.reports.SalesSummary;
import com.sedcore.repository.PurchaseRepository;
import com.sedcore.repository.SaleRepository;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.service.SalesReportService;
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
import java.util.stream.Collectors;

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

        List<Sale> allSales = (List<Sale>) saleRepository.findAll();
        List<Sale> filtered = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .collect(Collectors.toList());

        BigDecimal totalRevenue = filtered.stream()
                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalPaid = filtered.stream()
                .map(s -> s.getPaidAmount() != null ? s.getPaidAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgOrder = !filtered.isEmpty()
                ? totalRevenue.divide(BigDecimal.valueOf(filtered.size()), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // Period grouping
        String pattern = "month".equalsIgnoreCase(groupBy) ? "yyyy-MM" : "yyyy-MM-dd";
        DateTimeFormatter df = DateTimeFormatter.ofPattern(pattern);

        Map<String, List<Sale>> grouped = filtered.stream()
                .collect(Collectors.groupingBy(s -> s.getSaleDate().format(df)));

        List<SalesSummary.PeriodData> periodData = grouped.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> SalesSummary.PeriodData.builder()
                        .period(e.getKey())
                        .salesCount((long) e.getValue().size())
                        .revenue(e.getValue().stream()
                                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .paidAmount(e.getValue().stream()
                                .map(s -> s.getPaidAmount() != null ? s.getPaidAmount() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add))
                        .build())
                .collect(Collectors.toList());

        return SalesSummary.builder()
                .totalSalesCount((long) filtered.size())
                .totalRevenue(totalRevenue)
                .averageOrderValue(avgOrder)
                .totalPaidAmount(totalPaid)
                .totalDebtAmount(totalRevenue.subtract(totalPaid))
                .periodData(periodData)
                .build();
    }

    @Override
    public List<ProductSalesAnalysis> getProductSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit) {
        log.info("Urun satis analizi: {} - {}, limit={}", startDate, endDate, limit);

        List<StockMovement> allMovements = (List<StockMovement>) stockMovementRepository.findAll();
        List<StockMovement> saleMovements = allMovements.stream()
                .filter(m -> m.getMovementType() == StockMovementType.SALE_OUT)
                .filter(m -> m.getCreateTime() != null
                        && !toLocalDateTime(m.getCreateTime()).isBefore(startDate)
                        && !toLocalDateTime(m.getCreateTime()).isAfter(endDate))
                .collect(Collectors.toList());

        // Group by variant
        Map<String, List<StockMovement>> byVariant = saleMovements.stream()
                .filter(m -> m.getVariant() != null)
                .collect(Collectors.groupingBy(m -> m.getVariant().getId()));

        List<ProductSalesAnalysis> result = byVariant.entrySet().stream()
                .map(e -> {
                    StockMovement first = e.getValue().get(0);
                    int totalQty = e.getValue().stream()
                            .mapToInt(m -> m.getQuantity() != null ? m.getQuantity() : 0)
                            .sum();
                    BigDecimal totalRev = e.getValue().stream()
                            .map(m -> {
                                BigDecimal price = m.getUnitPrice() != null ? m.getUnitPrice() : BigDecimal.ZERO;
                                int qty = m.getQuantity() != null ? m.getQuantity() : 0;
                                return price.multiply(BigDecimal.valueOf(qty));
                            })
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    BigDecimal avgPrice = totalQty > 0
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
                .sorted(Comparator.comparing(ProductSalesAnalysis::getTotalRevenue).reversed())
                .limit(limit)
                .collect(Collectors.toList());

        return result;
    }

    @Override
    public List<CustomerSalesAnalysis> getCustomerSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit) {
        log.info("Musteri satis analizi: {} - {}, limit={}", startDate, endDate, limit);

        List<Sale> allSales = (List<Sale>) saleRepository.findAll();
        List<Sale> filtered = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .filter(s -> s.getCustomer() != null)
                .collect(Collectors.toList());

        Map<String, List<Sale>> byCustomer = filtered.stream()
                .collect(Collectors.groupingBy(s -> s.getCustomer().getId()));

        List<CustomerSalesAnalysis> result = byCustomer.entrySet().stream()
                .map(e -> {
                    Sale first = e.getValue().get(0);
                    BigDecimal totalSpent = e.getValue().stream()
                            .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    BigDecimal avgOrder = totalSpent.divide(
                            BigDecimal.valueOf(e.getValue().size()), 2, RoundingMode.HALF_UP);
                    LocalDateTime lastDate = e.getValue().stream()
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
                .sorted(Comparator.comparing(CustomerSalesAnalysis::getTotalSpent).reversed())
                .limit(limit)
                .collect(Collectors.toList());

        return result;
    }

    @Override
    public ProfitOverview getProfitOverview(LocalDateTime startDate, LocalDateTime endDate) {
        log.info("Kar/zarar ozeti: {} - {}", startDate, endDate);

        // Revenue from sales
        List<Sale> allSales = (List<Sale>) saleRepository.findAll();
        List<Sale> filteredSales = allSales.stream()
                .filter(s -> !Boolean.TRUE.equals(s.getIsCancelled()))
                .filter(s -> s.getSaleDate() != null
                        && !s.getSaleDate().isBefore(startDate)
                        && !s.getSaleDate().isAfter(endDate))
                .collect(Collectors.toList());

        BigDecimal totalRevenue = filteredSales.stream()
                .map(s -> s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Cost from purchase movements in the period
        List<StockMovement> allMovements = (List<StockMovement>) stockMovementRepository.findAll();
        BigDecimal totalCost = allMovements.stream()
                .filter(m -> m.getMovementType() == StockMovementType.SALE_OUT)
                .filter(m -> m.getCreateTime() != null
                        && !toLocalDateTime(m.getCreateTime()).isBefore(startDate)
                        && !toLocalDateTime(m.getCreateTime()).isAfter(endDate))
                .map(m -> {
                    BigDecimal price = m.getUnitPrice() != null ? m.getUnitPrice() : BigDecimal.ZERO;
                    int qty = m.getQuantity() != null ? m.getQuantity() : 0;
                    return price.multiply(BigDecimal.valueOf(qty));
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal grossProfit = totalRevenue.subtract(totalCost);
        BigDecimal margin = totalRevenue.compareTo(BigDecimal.ZERO) > 0
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
