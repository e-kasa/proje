package com.sedcore.finance.service;

import com.sedcore.finance.model.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface FinanceService {

    // Expenses
    List<ExpenseResponse> getExpenses(String category, String status, LocalDateTime startDate, LocalDateTime endDate);
    ExpenseResponse getExpenseById(String id);
    ExpenseResponse createExpense(ExpenseRequest request);
    ExpenseResponse updateExpense(String id, ExpenseRequest request);
    void deleteExpense(String id);

    // Revenues
    List<RevenueResponse> getRevenues(String category, LocalDateTime startDate, LocalDateTime endDate);
    RevenueResponse createRevenue(RevenueRequest request);
    void deleteRevenue(String id);

    // Summary
    FinanceSummary getSummary(LocalDateTime startDate, LocalDateTime endDate);

    // Categories
    List<Map<String, Object>> getExpenseCategories();
}
