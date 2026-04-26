package com.sedcore.finance.controller.impl;

import com.sedcore.finance.model.PaginatedAccountsResponse;
import com.sedcore.finance.service.AccountsListService;
import com.towpen.base.exceptions.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sprint 8 B0 — Birleşik cari hesap liste endpoint'i (cursor pagination).
 *
 * <p>Mevcut /customers + /suppliers ayrı endpoint'leri yerine birleşik akış —
 * sayfa sınırı 2 koleksiyon arası kayıp önlenir, frontend tek istek ile
 * scroll-up infinite list besler.
 *
 * <p>Cevap: {@link PaginatedAccountsResponse}.
 */
@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Accounts List", description = "Sayfalı cari hesap listesi (Sprint 8)")
@SecurityRequirement(name = "Bearer Authentication")
public class AccountsListControllerImpl {

    private final AccountsListService accountsListService;

    /**
     * GET /product/api/v1/accounts/list
     *
     * @param cursor  JSON cursor (önceki sayfanın nextCursor'ı). null = ilk sayfa.
     * @param limit   sayfa boyutu (1..50, default 20)
     * @param filter  "all" | "customer" | "supplier" | "overdue" (default "all")
     * @param q       isim arama (case-insensitive contains)
     */
    @GetMapping("/list")
    @Operation(summary = "List accounts (cursor pagination)",
               description = "Cari hesap listesi — birleşik customer + supplier, cursor-based.")
    public ResponseEntity<ApiResponse<PaginatedAccountsResponse>> list(
            @Parameter(description = "JSON cursor (boş = ilk sayfa)")
            @RequestParam(required = false) String cursor,

            @Parameter(description = "Sayfa boyutu (1..50)")
            @RequestParam(required = false, defaultValue = "20") int limit,

            @Parameter(description = "Filter: all | customer | supplier | overdue")
            @RequestParam(required = false, defaultValue = "all") String filter,

            @Parameter(description = "İsim arama (contains, case-insensitive)")
            @RequestParam(required = false) String q
    ) {
        log.debug("GET /accounts/list cursor={} limit={} filter={} q={}", cursor, limit, filter, q);
        PaginatedAccountsResponse response = accountsListService.list(cursor, limit, filter, q);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
