package com.sedcore.service;

import com.sedcore.model.reports.CriticalStockAlert;
import com.sedcore.model.reports.StockMovementSummary;
import com.sedcore.model.reports.StockValueSummary;

import java.time.LocalDateTime;
import java.util.List;

public interface StockReportService {

    StockValueSummary getStockValueSummary();

    StockMovementSummary getMovementSummary(LocalDateTime startDate, LocalDateTime endDate);

    List<CriticalStockAlert> getCriticalAlerts();

    StockValueSummary getWarehouseBreakdown(String warehouseId);
}
