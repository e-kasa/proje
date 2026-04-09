package com.sedcore.service.impl;

import com.sedcore.entity.InventoryView;
import com.sedcore.entity.ProductVariant;
import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.reports.CriticalStockAlert;
import com.sedcore.model.reports.StockMovementSummary;
import com.sedcore.model.reports.StockValueSummary;
import com.sedcore.repository.InventoryRepository;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.service.StockReportService;
import lombok.RequiredArgsConstructor;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
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
public class StockReportServiceImpl implements StockReportService {

    private final InventoryRepository inventoryRepository;
    private final StockMovementRepository stockMovementRepository;
    private final ProductVariantRepository productVariantRepository;

    @Override
    public StockValueSummary getStockValueSummary() {
        log.info("Stok deger ozeti hesaplaniyor");

        List<InventoryView> allInventory = (List<InventoryView>) inventoryRepository.findAll();
        List<ProductVariant> allVariants = (List<ProductVariant>) productVariantRepository.findAll();

        Map<String, ProductVariant> variantMap = allVariants.stream()
                .collect(Collectors.toMap(ProductVariant::getId, v -> v, (a, b) -> a));

        BigDecimal totalValue = BigDecimal.ZERO;
        long totalSku = 0;

        // Warehouse breakdown
        Map<String, StockValueSummary.WarehouseBreakdown> warehouseMap = new HashMap<>();

        for (InventoryView inv : allInventory) {
            ProductVariant variant = variantMap.get(inv.getVariantId());
            if (variant == null || inv.getPhysicalQuantity() == null) continue;

            BigDecimal unitPrice = variant.getAdditionalPrice() != null
                    ? variant.getAdditionalPrice() : BigDecimal.ZERO;
            BigDecimal itemValue = unitPrice.multiply(BigDecimal.valueOf(inv.getPhysicalQuantity()));

            totalValue = totalValue.add(itemValue);
            totalSku++;

            String whKey = inv.getWarehouseId() != null ? inv.getWarehouseId() : "unknown";
            warehouseMap.computeIfAbsent(whKey, k -> StockValueSummary.WarehouseBreakdown.builder()
                            .warehouseId(k).warehouseName(k).itemCount(0L).totalQuantity(0).totalValue(BigDecimal.ZERO).build())
                    .setItemCount(warehouseMap.get(whKey).getItemCount() + 1);
            StockValueSummary.WarehouseBreakdown wb = warehouseMap.get(whKey);
            wb.setTotalQuantity(wb.getTotalQuantity() + inv.getPhysicalQuantity());
            wb.setTotalValue(wb.getTotalValue().add(itemValue));
        }

        BigDecimal avgValue = totalSku > 0
                ? totalValue.divide(BigDecimal.valueOf(totalSku), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return StockValueSummary.builder()
                .totalStockValue(totalValue)
                .totalSkuCount(totalSku)
                .averageItemValue(avgValue)
                .warehouseBreakdowns(new ArrayList<>(warehouseMap.values()))
                .categoryBreakdowns(new ArrayList<>())
                .build();
    }

    @Override
    public StockMovementSummary getMovementSummary(LocalDateTime startDate, LocalDateTime endDate) {
        log.info("Stok hareket ozeti: {} - {}", startDate, endDate);

        List<StockMovement> movements = (List<StockMovement>) stockMovementRepository.findAll();
        List<StockMovement> filtered = movements.stream()
                .filter(m -> m.getCreateTime() != null
                        && !toLocalDateTime(m.getCreateTime()).isBefore(startDate)
                        && !toLocalDateTime(m.getCreateTime()).isAfter(endDate))
                .collect(Collectors.toList());

        long totalIn = filtered.stream()
                .filter(m -> m.getMovementType() != null && m.getMovementType().name().endsWith("_IN"))
                .count();
        long totalOut = filtered.stream()
                .filter(m -> m.getMovementType() != null && m.getMovementType().name().endsWith("_OUT"))
                .count();

        Map<StockMovementType, Long> countByType = filtered.stream()
                .filter(m -> m.getMovementType() != null)
                .collect(Collectors.groupingBy(StockMovement::getMovementType, Collectors.counting()));

        // Daily grouping
        DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        Map<String, List<StockMovement>> byDay = filtered.stream()
                .filter(m -> m.getCreateTime() != null)
                .collect(Collectors.groupingBy(m -> toLocalDateTime(m.getCreateTime()).format(df)));

        List<StockMovementSummary.DailyMovement> dailyMovements = byDay.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> {
                    long dayIn = e.getValue().stream()
                            .filter(m -> m.getMovementType() != null && m.getMovementType().name().endsWith("_IN"))
                            .count();
                    long dayOut = e.getValue().stream()
                            .filter(m -> m.getMovementType() != null && m.getMovementType().name().endsWith("_OUT"))
                            .count();
                    return StockMovementSummary.DailyMovement.builder()
                            .date(e.getKey())
                            .inCount(dayIn)
                            .outCount(dayOut)
                            .totalCount((long) e.getValue().size())
                            .build();
                })
                .collect(Collectors.toList());

        return StockMovementSummary.builder()
                .totalMovements((long) filtered.size())
                .totalIn(totalIn)
                .totalOut(totalOut)
                .countByType(countByType)
                .dailyMovements(dailyMovements)
                .build();
    }

    @Override
    public List<CriticalStockAlert> getCriticalAlerts() {
        log.info("Kritik stok alarmlari hesaplaniyor");

        List<InventoryView> allInventory = (List<InventoryView>) inventoryRepository.findAll();
        List<ProductVariant> allVariants = (List<ProductVariant>) productVariantRepository.findAll();

        Map<String, ProductVariant> variantMap = allVariants.stream()
                .collect(Collectors.toMap(ProductVariant::getId, v -> v, (a, b) -> a));

        List<CriticalStockAlert> alerts = new ArrayList<>();

        for (InventoryView inv : allInventory) {
            ProductVariant variant = variantMap.get(inv.getVariantId());
            if (variant == null) continue;

            int qty = inv.getPhysicalQuantity() != null ? inv.getPhysicalQuantity() : 0;
            int minStock = variant.getMinStockLevel() != null ? variant.getMinStockLevel() : 10;

            if (qty <= minStock) {
                String alertLevel;
                if (qty == 0) alertLevel = "OUT_OF_STOCK";
                else if (qty <= 5) alertLevel = "CRITICAL";
                else alertLevel = "LOW";

                String productName = variant.getProduct() != null ? variant.getProduct().getName() : "";

                alerts.add(CriticalStockAlert.builder()
                        .variantId(variant.getId())
                        .variantSku(variant.getSku())
                        .variantName(variant.getName())
                        .productName(productName)
                        .currentQuantity(qty)
                        .minimumThreshold(minStock)
                        .warehouseId(inv.getWarehouseId())
                        .storeId(inv.getStoreId())
                        .alertLevel(alertLevel)
                        .build());
            }
        }

        alerts.sort(Comparator.comparingInt(CriticalStockAlert::getCurrentQuantity));
        return alerts;
    }

    @Override
    public StockValueSummary getWarehouseBreakdown(String warehouseId) {
        log.info("Depo stok detayi: warehouseId={}", warehouseId);

        List<InventoryView> inventory = inventoryRepository.findByWarehouseId(warehouseId);
        List<ProductVariant> allVariants = (List<ProductVariant>) productVariantRepository.findAll();

        Map<String, ProductVariant> variantMap = allVariants.stream()
                .collect(Collectors.toMap(ProductVariant::getId, v -> v, (a, b) -> a));

        BigDecimal totalValue = BigDecimal.ZERO;
        long totalSku = 0;
        int totalQty = 0;

        for (InventoryView inv : inventory) {
            ProductVariant variant = variantMap.get(inv.getVariantId());
            if (variant == null || inv.getPhysicalQuantity() == null) continue;

            BigDecimal unitPrice = variant.getAdditionalPrice() != null
                    ? variant.getAdditionalPrice() : BigDecimal.ZERO;
            totalValue = totalValue.add(unitPrice.multiply(BigDecimal.valueOf(inv.getPhysicalQuantity())));
            totalSku++;
            totalQty += inv.getPhysicalQuantity();
        }

        BigDecimal avgValue = totalSku > 0
                ? totalValue.divide(BigDecimal.valueOf(totalSku), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return StockValueSummary.builder()
                .totalStockValue(totalValue)
                .totalSkuCount(totalSku)
                .averageItemValue(avgValue)
                .warehouseBreakdowns(List.of(StockValueSummary.WarehouseBreakdown.builder()
                        .warehouseId(warehouseId)
                        .warehouseName(warehouseId)
                        .itemCount(totalSku)
                        .totalQuantity(totalQty)
                        .totalValue(totalValue)
                        .build()))
                .categoryBreakdowns(new ArrayList<>())
                .build();
    }

    private LocalDateTime toLocalDateTime(Date date) {
        return date.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
    }
}
