package com.sedcore.inventory.service;

import com.sedcore.inventory.model.CriticalStockAlert;
import com.sedcore.inventory.model.StockMovementSummary;
import com.sedcore.inventory.model.StockValueSummary;

import java.time.LocalDateTime;
import java.util.List;

public interface StockReportService {

    StockValueSummary getStockValueSummary();

    StockMovementSummary getMovementSummary(LocalDateTime startDate, LocalDateTime endDate);

    List<CriticalStockAlert> getCriticalAlerts();

    StockValueSummary getWarehouseBreakdown(String locationId);
}
