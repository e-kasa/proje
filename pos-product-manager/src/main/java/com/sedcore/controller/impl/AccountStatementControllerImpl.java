package com.sedcore.controller.impl;

import com.sedcore.entity.AccountTransaction;
import com.sedcore.model.reports.AccountStatementEntry;
import com.sedcore.repository.AccountTransactionRepository;
import com.sedcore.se.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/account-statements")
@RequiredArgsConstructor
@Slf4j
public class AccountStatementControllerImpl {

    private final AccountTransactionRepository accountTransactionRepository;

    // GET /product/api/v1/account-statements
    @GetMapping
    public ResponseEntity<ApiResponse<AccountStatementEntry>> getStatement(
            @RequestParam String accountType,
            @RequestParam String accountId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            List<AccountTransaction> transactions;
            if ("CUSTOMER".equalsIgnoreCase(accountType)) {
                transactions = accountTransactionRepository.findByCustomerId(accountId);
            } else {
                transactions = accountTransactionRepository.findBySupplierId(accountId);
            }

            // Filter by date and sort
            List<AccountTransaction> filtered = transactions.stream()
                    .filter(t -> !Boolean.TRUE.equals(t.getIsCancelled()))
                    .filter(t -> t.getTransactionDate() != null
                            && !t.getTransactionDate().isBefore(startDate)
                            && !t.getTransactionDate().isAfter(endDate))
                    .sorted(Comparator.comparing(AccountTransaction::getTransactionDate))
                    .collect(Collectors.toList());

            // Calculate opening balance from transactions before startDate
            BigDecimal openingBalance = transactions.stream()
                    .filter(t -> !Boolean.TRUE.equals(t.getIsCancelled()))
                    .filter(t -> t.getTransactionDate() != null && t.getTransactionDate().isBefore(startDate))
                    .map(t -> t.getDebitAmount().subtract(t.getCreditAmount()))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            // Build transaction lines with running balance
            BigDecimal runningBalance = openingBalance;
            BigDecimal totalDebit = BigDecimal.ZERO;
            BigDecimal totalCredit = BigDecimal.ZERO;
            List<AccountStatementEntry.TransactionLine> lines = new ArrayList<>();

            for (AccountTransaction t : filtered) {
                runningBalance = runningBalance.add(t.getDebitAmount()).subtract(t.getCreditAmount());
                totalDebit = totalDebit.add(t.getDebitAmount());
                totalCredit = totalCredit.add(t.getCreditAmount());

                lines.add(AccountStatementEntry.TransactionLine.builder()
                        .id(t.getId())
                        .transactionDate(t.getTransactionDate())
                        .transactionType(t.getTransactionType())
                        .description(t.getDescription())
                        .referenceNumber(t.getReferenceNumber())
                        .debitAmount(t.getDebitAmount())
                        .creditAmount(t.getCreditAmount())
                        .runningBalance(runningBalance)
                        .build());
            }

            AccountStatementEntry entry = AccountStatementEntry.builder()
                    .openingBalance(openingBalance)
                    .closingBalance(runningBalance)
                    .totalDebit(totalDebit)
                    .totalCredit(totalCredit)
                    .transactions(lines)
                    .build();

            return ResponseEntity.ok(ApiResponse.success(entry));
        } catch (Exception e) {
            log.error("Hesap ekstresi hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/account-statements/overdue
    @GetMapping("/overdue")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getOverdue(
            @RequestParam(required = false) String accountType) {
        try {
            List<AccountTransaction> all = (List<AccountTransaction>) accountTransactionRepository.findAll();
            List<AccountTransaction> overdue = all.stream()
                    .filter(t -> !Boolean.TRUE.equals(t.getIsCancelled()))
                    .filter(t -> Boolean.TRUE.equals(t.getIsOverdue()) || t.checkOverdue())
                    .filter(t -> {
                        if ("CUSTOMER".equalsIgnoreCase(accountType)) return t.getCustomer() != null;
                        if ("SUPPLIER".equalsIgnoreCase(accountType)) return t.getSupplier() != null;
                        return true;
                    })
                    .sorted(Comparator.comparing(t -> t.getDueDate() != null ? t.getDueDate() : java.time.LocalDate.MAX))
                    .collect(Collectors.toList());

            List<Map<String, Object>> result = overdue.stream()
                    .map(t -> {
                        Map<String, Object> m = new HashMap<>();
                        m.put("id", t.getId());
                        m.put("transactionType", t.getTransactionType());
                        m.put("debitAmount", t.getDebitAmount());
                        m.put("creditAmount", t.getCreditAmount());
                        m.put("dueDate", t.getDueDate());
                        m.put("description", t.getDescription());
                        m.put("referenceNumber", t.getReferenceNumber());
                        if (t.getCustomer() != null) {
                            m.put("accountType", "CUSTOMER");
                            m.put("accountId", t.getCustomer().getId());
                            m.put("accountName", t.getCustomer().getName());
                        } else if (t.getSupplier() != null) {
                            m.put("accountType", "SUPPLIER");
                            m.put("accountId", t.getSupplier().getId());
                            m.put("accountName", t.getSupplier().getName());
                        }
                        return m;
                    })
                    .collect(Collectors.toList());

            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (Exception e) {
            log.error("Vadesi gecmis islemler hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/account-statements/summary
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSummary(
            @RequestParam(required = false) String accountType) {
        try {
            List<AccountTransaction> all = (List<AccountTransaction>) accountTransactionRepository.findAll();
            List<AccountTransaction> active = all.stream()
                    .filter(t -> !Boolean.TRUE.equals(t.getIsCancelled()))
                    .collect(Collectors.toList());

            Map<String, Object> summary = new HashMap<>();

            // Customer totals
            BigDecimal totalCustomerDebt = active.stream()
                    .filter(t -> t.getCustomer() != null)
                    .map(t -> t.getDebitAmount().subtract(t.getCreditAmount()))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalSupplierDebt = active.stream()
                    .filter(t -> t.getSupplier() != null)
                    .map(t -> t.getDebitAmount().subtract(t.getCreditAmount()))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalOverdue = active.stream()
                    .filter(t -> Boolean.TRUE.equals(t.getIsOverdue()) || t.checkOverdue())
                    .map(t -> t.getDebitAmount().subtract(t.getCreditAmount()))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            long overdueCount = active.stream()
                    .filter(t -> Boolean.TRUE.equals(t.getIsOverdue()) || t.checkOverdue())
                    .count();

            summary.put("totalCustomerReceivable", totalCustomerDebt);
            summary.put("totalSupplierPayable", totalSupplierDebt);
            summary.put("totalOverdueAmount", totalOverdue);
            summary.put("overdueTransactionCount", overdueCount);
            summary.put("totalTransactionCount", (long) active.size());

            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (Exception e) {
            log.error("Hesap ozeti hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }
}
