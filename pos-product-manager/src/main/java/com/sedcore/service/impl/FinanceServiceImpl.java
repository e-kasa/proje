package com.sedcore.service.impl;

import com.sedcore.context.CompanyContext;
import com.sedcore.entity.Expense;
import com.sedcore.entity.Revenue;
import com.sedcore.model.finance.*;
import com.sedcore.repository.ExpenseRepository;
import com.sedcore.repository.RevenueRepository;
import com.sedcore.service.FinanceService;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class FinanceServiceImpl implements FinanceService {

    private final ExpenseRepository expenseRepository;
    private final RevenueRepository revenueRepository;

    private String companyCode() {
        String code = CompanyContext.get();
        return (code == null || code.isBlank()) ? "syste" : code;
    }

    // ─── Expenses ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getExpenses(String category, String status, LocalDateTime startDate, LocalDateTime endDate) {
        String cc = companyCode();
        List<Expense> expenses;

        if (startDate != null && endDate != null) {
            expenses = expenseRepository.findByCompanyCodeAndExpenseDateBetweenAndIsDeletedFalse(cc, startDate, endDate);
        } else if (category != null && !category.isBlank()) {
            expenses = expenseRepository.findByCompanyCodeAndCategoryAndIsDeletedFalse(cc, category);
        } else {
            expenses = expenseRepository.findByCompanyCodeAndIsDeletedFalseOrderByExpenseDateDesc(cc);
        }

        if (status != null && !status.isBlank()) {
            expenses = expenses.stream()
                    .filter(e -> status.equalsIgnoreCase(e.getStatus()))
                    .collect(Collectors.toList());
        }

        return expenses.stream().map(this::toExpenseResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ExpenseResponse getExpenseById(String id) {
        return expenseRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, companyCode())
                .map(this::toExpenseResponse)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
    }

    @Override
    public ExpenseResponse createExpense(ExpenseRequest request) {
        Expense expense = Expense.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .amount(request.getAmount())
                .category(request.getCategory())
                .expenseDate(request.getExpenseDate() != null ? request.getExpenseDate() : LocalDateTime.now())
                .paymentMethod(request.getPaymentMethod())
                .referenceNumber(request.getReferenceNumber())
                .status(request.getStatus() != null ? request.getStatus() : "PAID")
                .build();
        expenseRepository.save(expense);
        log.info("Gider oluşturuldu: {} - {}", expense.getTitle(), expense.getId());
        return toExpenseResponse(expense);
    }

    @Override
    public ExpenseResponse updateExpense(String id, ExpenseRequest request) {
        Expense expense = expenseRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, companyCode())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        expense.setTitle(request.getTitle());
        expense.setDescription(request.getDescription());
        expense.setAmount(request.getAmount());
        expense.setCategory(request.getCategory());
        if (request.getExpenseDate() != null) expense.setExpenseDate(request.getExpenseDate());
        expense.setPaymentMethod(request.getPaymentMethod());
        expense.setReferenceNumber(request.getReferenceNumber());
        if (request.getStatus() != null) expense.setStatus(request.getStatus());
        expenseRepository.save(expense);
        return toExpenseResponse(expense);
    }

    @Override
    public void deleteExpense(String id) {
        Expense expense = expenseRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, companyCode())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        expense.setIsDeleted(true);
        expenseRepository.save(expense);
        log.info("Gider silindi: {}", id);
    }

    // ─── Revenues ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<RevenueResponse> getRevenues(String category, LocalDateTime startDate, LocalDateTime endDate) {
        String cc = companyCode();
        List<Revenue> revenues;

        if (startDate != null && endDate != null) {
            revenues = revenueRepository.findByCompanyCodeAndRevenueDateBetweenAndIsDeletedFalse(cc, startDate, endDate);
        } else {
            revenues = revenueRepository.findByCompanyCodeAndIsDeletedFalseOrderByRevenueDateDesc(cc);
        }
        return revenues.stream().map(this::toRevenueResponse).collect(Collectors.toList());
    }

    @Override
    public RevenueResponse createRevenue(RevenueRequest request) {
        Revenue revenue = Revenue.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .amount(request.getAmount())
                .category(request.getCategory())
                .revenueDate(request.getRevenueDate() != null ? request.getRevenueDate() : LocalDateTime.now())
                .paymentMethod(request.getPaymentMethod())
                .referenceNumber(request.getReferenceNumber())
                .build();
        revenueRepository.save(revenue);
        log.info("Gelir oluşturuldu: {} - {}", revenue.getTitle(), revenue.getId());
        return toRevenueResponse(revenue);
    }

    @Override
    public void deleteRevenue(String id) {
        Revenue revenue = revenueRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, companyCode())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        revenue.setIsDeleted(true);
        revenueRepository.save(revenue);
    }

    // ─── Summary ─────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public FinanceSummary getSummary(LocalDateTime startDate, LocalDateTime endDate) {
        String cc = companyCode();
        LocalDateTime from = startDate != null ? startDate : LocalDateTime.now().minusDays(30);
        LocalDateTime to = endDate != null ? endDate : LocalDateTime.now();

        List<Revenue> revenues = revenueRepository.findByCompanyCodeAndRevenueDateBetweenAndIsDeletedFalse(cc, from, to);
        List<Expense> expenses = expenseRepository.findByCompanyCodeAndExpenseDateBetweenAndIsDeletedFalse(cc, from, to);

        BigDecimal totalRevenue = revenues.stream()
                .map(Revenue::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalExpense = expenses.stream()
                .map(Expense::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return FinanceSummary.builder()
                .totalRevenue(totalRevenue)
                .totalExpense(totalExpense)
                .netProfit(totalRevenue.subtract(totalExpense))
                .revenueCount(revenues.size())
                .expenseCount(expenses.size())
                .build();
    }

    // ─── Categories ──────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getExpenseCategories() {
        List<String> categories = Arrays.asList(
                "Kira", "Maaş", "Fatura", "Ulaşım", "Malzeme",
                "Pazarlama", "Bakım-Onarım", "Vergi", "Sigorta", "Diğer"
        );
        return categories.stream().map(c -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", c.toLowerCase().replace(" ", "_").replace("-", "_"));
            map.put("name", c);
            return map;
        }).collect(Collectors.toList());
    }

    // ─── Mappers ─────────────────────────────────────────────────────

    private ExpenseResponse toExpenseResponse(Expense e) {
        return ExpenseResponse.builder()
                .id(e.getId())
                .title(e.getTitle())
                .description(e.getDescription())
                .amount(e.getAmount())
                .category(e.getCategory())
                .expenseDate(e.getExpenseDate())
                .paymentMethod(e.getPaymentMethod())
                .referenceNumber(e.getReferenceNumber())
                .status(e.getStatus())
                .createTime(e.getCreateTime())
                .build();
    }

    private RevenueResponse toRevenueResponse(Revenue r) {
        return RevenueResponse.builder()
                .id(r.getId())
                .title(r.getTitle())
                .description(r.getDescription())
                .amount(r.getAmount())
                .category(r.getCategory())
                .revenueDate(r.getRevenueDate())
                .paymentMethod(r.getPaymentMethod())
                .referenceNumber(r.getReferenceNumber())
                .createTime(r.getCreateTime())
                .build();
    }
}
