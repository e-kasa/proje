package com.sedcore.sales.service;

import com.sedcore.sales.model.CustomerSalesAnalysis;
import com.sedcore.sales.model.ProductSalesAnalysis;
import com.sedcore.sales.model.ProfitOverview;
import com.sedcore.sales.model.SalesSummary;

import java.time.LocalDateTime;
import java.util.List;

public interface SalesReportService {

    SalesSummary getSalesSummary(LocalDateTime startDate, LocalDateTime endDate, String groupBy);

    List<ProductSalesAnalysis> getProductSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit);

    List<CustomerSalesAnalysis> getCustomerSalesAnalysis(LocalDateTime startDate, LocalDateTime endDate, int limit);

    ProfitOverview getProfitOverview(LocalDateTime startDate, LocalDateTime endDate);
}
