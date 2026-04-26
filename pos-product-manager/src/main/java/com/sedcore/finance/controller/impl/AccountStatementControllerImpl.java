package com.sedcore.finance.controller.impl;

import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.finance.model.AccountStatementEntry;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.sedcore.supplier.service.SupplierAccountService;
import com.sedcore.supplier.service.SupplierService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.sedcore.common.util.ExceptionMapper;

import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

@RestController
@RequestMapping("api/v1/account-statements")
@RequiredArgsConstructor
@Slf4j
public class AccountStatementControllerImpl {

    private final AccountTransactionRepository accountTransactionRepository;
    private final CustomerService customerService;
    private final CustomerAccountService customerAccountService;
    private final SupplierService supplierService;
    private final SupplierAccountService supplierAccountService;

    // GET /product/api/v1/account-statements
    // DB-side filter + sort (idx_customer_cancel_date / idx_supplier_date);
    // opening balance as a single scalar aggregate.
    @Transactional(readOnly = true)
    @GetMapping
    public ResponseEntity<ApiResponse<AccountStatementEntry>> getStatement(
            @RequestParam String accountType,
            @RequestParam String accountId,
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDateParam,
            @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDateParam) {
        try {
            LocalDateTime startDate = startDateParam.atStartOfDay();
            LocalDateTime endDate = endDateParam.atTime(LocalTime.MAX);

            final boolean isCustomer = "CUSTOMER".equalsIgnoreCase(accountType);

            List<AccountTransaction> filtered = isCustomer
                    ? accountTransactionRepository.findCustomerStatement(accountId, startDate, endDate)
                    : accountTransactionRepository.findSupplierStatement(accountId, startDate, endDate);

            BigDecimal openingBalance = isCustomer
                    ? accountTransactionRepository.customerOpeningBalance(accountId, startDate)
                    : accountTransactionRepository.supplierOpeningBalance(accountId, startDate);
            if (openingBalance == null) openingBalance = BigDecimal.ZERO;

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

            // Sprint 8 hot-fix (Bug B): denormalize currentBalance ekle.
            // Frontend bu değeri primer bakiye olarak gösterir; closingBalance
            // transaction toplamı, currentBalance ise CustomerAccount/SupplierAccount
            // denormalize değeri (write-through cache). İkisi farklıysa drift uyarısı.
            BigDecimal currentBalance = BigDecimal.ZERO;
            try {
                if (isCustomer) {
                    var acct = customerAccountService.getOrCreate(customerService.getEntity(accountId));
                    if (acct != null && acct.getCurrentBalance() != null) {
                        currentBalance = acct.getCurrentBalance();
                    }
                } else {
                    var supplier = supplierService.findById(accountId).orElse(null);
                    if (supplier != null) {
                        var acct = supplierAccountService.getOrCreate(supplier);
                        if (acct != null && acct.getCurrentBalance() != null) {
                            currentBalance = acct.getCurrentBalance();
                        }
                    }
                }
            } catch (Exception ex) {
                log.warn("currentBalance fetch failed for {}/{}: {}", accountType, accountId, ex.getMessage());
                currentBalance = runningBalance; // fallback: closingBalance
            }

            AccountStatementEntry entry = AccountStatementEntry.builder()
                    .openingBalance(openingBalance)
                    .closingBalance(runningBalance)
                    .currentBalance(currentBalance)
                    .totalDebit(totalDebit)
                    .totalCredit(totalCredit)
                    .transactions(lines)
                    .build();

            return ResponseEntity.ok(ApiResponse.success(entry));
        } catch (Exception e) {
            log.error("Hesap ekstresi hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/account-statements/overdue
    // DB-side filter + sort via idx_overdue_hot; LEFT JOIN FETCH avoids N+1 on customer/supplier.
    @Transactional(readOnly = true)
    @GetMapping("/overdue")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getOverdue(
            @RequestParam(required = false) String accountType) {
        try {
            String typeParam = accountType == null ? null : accountType.toUpperCase();
            List<AccountTransaction> overdue =
                    accountTransactionRepository.findOverdue(typeParam);

            List<Map<String, Object>> result = new ArrayList<>(overdue.size());
            for (AccountTransaction t : overdue) {
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
                result.add(m);
            }

            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (Exception e) {
            log.error("Vadesi gecmis islemler hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/account-statements/summary
    // Single round-trip: one scalar aggregate @Query instead of findAll() + 4 stream passes.
    // accountType parameter preserved for backwards-compat; aggregation already separates by entity.
    @Transactional(readOnly = true)
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSummary(
            @RequestParam(required = false) String accountType) {
        try {
            Object[] agg = accountTransactionRepository.fetchSummaryAggregates();

            // JPQL returns: [BigDecimal, BigDecimal, BigDecimal, Long, Long]
            Object[] row = unwrapAggRow(agg);

            BigDecimal totalCustomerDebt = asBigDecimal(row[0]);
            BigDecimal totalSupplierDebt = asBigDecimal(row[1]);
            BigDecimal totalOverdue = asBigDecimal(row[2]);
            long overdueCount = asLong(row[3]);
            long totalTxCount = asLong(row[4]);

            Map<String, Object> summary = new HashMap<>();
            summary.put("totalCustomerReceivable", totalCustomerDebt);
            summary.put("totalSupplierPayable", totalSupplierDebt);
            summary.put("totalOverdueAmount", totalOverdue);
            summary.put("overdueTransactionCount", overdueCount);
            summary.put("totalTransactionCount", totalTxCount);

            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (Exception e) {
            log.error("Hesap ozeti hatasi", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Hibernate can return either `Object[]` (5 columns) or `Object[]{Object[]{...}}`
     * depending on dialect/version. Normalize to the inner row.
     */
    private static Object[] unwrapAggRow(Object[] agg) {
        if (agg == null || agg.length == 0) {
            return new Object[]{BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L, 0L};
        }
        if (agg.length == 1 && agg[0] instanceof Object[] inner) {
            return inner;
        }
        return agg;
    }

    private static BigDecimal asBigDecimal(Object o) {
        if (o == null) return BigDecimal.ZERO;
        if (o instanceof BigDecimal bd) return bd;
        if (o instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return BigDecimal.ZERO;
    }

    private static long asLong(Object o) {
        if (o == null) return 0L;
        if (o instanceof Number n) return n.longValue();
        return 0L;
    }
}
