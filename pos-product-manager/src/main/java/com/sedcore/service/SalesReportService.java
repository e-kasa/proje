package com.sedcore.service;

import com.sedcore.model.reports.CustomerSalesAnalysis;
import com.sedcore.model.reports.ProductSalesAnalysis;
import com.sedcore.model.reports.ProfitOverview;
import com.sedcore.model.reports.SalesSummary;

import java.time.LocalDateTime;
import java.util.List;

public interface SalesReportService {

    SalesSummary getSalesSummary(LocalDateTime startDate, LocalDateTime endDate, String groupBy);

    List<ProductSalesAnalysis> getProductSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit);

    List<CustomerSalesAnalysis> getCustomerSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit);

    ProfitOverview getProfitOverview(LocalDateTime startDate, LocalDateTime endDate);
}
