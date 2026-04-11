package com.sedcore.finance.controller.impl;

import com.sedcore.finance.model.*;
import com.sedcore.finance.service.FinanceService;
import com.sedcore.common.util.ExceptionMapper;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("api/v1/finance")
@RequiredArgsConstructor
@Slf4j
public class FinanceControllerImpl {

    private final FinanceService financeService;

    // ─── Expenses ────────────────────────────────────────────────────

    @GetMapping("/expenses")
    public ResponseEntity<ApiResponse<List<ExpenseResponse>>> getExpenses(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    financeService.getExpenses(category, status, startDate, endDate)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gider listesi hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @GetMapping("/expenses/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> getExpenseById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.getExpenseById(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gider detay hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/expenses")
    public ResponseEntity<ApiResponse<ExpenseResponse>> createExpense(@Valid @RequestBody ExpenseRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.createExpense(request)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gider oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PutMapping("/expenses/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> updateExpense(
            @PathVariable String id, @Valid @RequestBody ExpenseRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.updateExpense(id, request)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gider güncelleme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @DeleteMapping("/expenses/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(@PathVariable String id) {
        try {
            financeService.deleteExpense(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gider silme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @GetMapping("/expense-categories")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getExpenseCategories() {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.getExpenseCategories()));
        } catch (Exception e) {
            log.error("Gider kategorileri hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    // ─── Revenues ────────────────────────────────────────────────────

    @GetMapping("/revenues")
    public ResponseEntity<ApiResponse<List<RevenueResponse>>> getRevenues(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    financeService.getRevenues(category, startDate, endDate)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gelir listesi hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/revenues")
    public ResponseEntity<ApiResponse<RevenueResponse>> createRevenue(@Valid @RequestBody RevenueRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.createRevenue(request)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gelir oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @DeleteMapping("/revenues/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRevenue(@PathVariable String id) {
        try {
            financeService.deleteRevenue(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gelir silme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    // ─── Summary ─────────────────────────────────────────────────────

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<FinanceSummary>> getSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            return ResponseEntity.ok(ApiResponse.success(financeService.getSummary(startDate, endDate)));
        } catch (Exception e) {
            log.error("Finans özeti hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
