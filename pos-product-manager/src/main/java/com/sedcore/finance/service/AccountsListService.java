package com.sedcore.finance.service;

import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.finance.model.AccountsListCursor;
import com.sedcore.finance.model.PaginatedAccountsResponse;
import com.sedcore.supplier.model.SupplierResponse;
import com.sedcore.supplier.service.SupplierService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Sprint 8 B0 — Cari hesap listesi sayfalı endpoint logic'i.
 *
 * <p>Şu anki implementasyon: in-memory merge + cursor (geliştirme dev DB için yeterli).
 * Production optimizasyonu (DB-side UNION + index) sprint sonunda yapılacak — bkz.
 * [[syntheses/sprint-8-implementation-plan-2026-04-26]] R1.
 *
 * <p>Sıralama anahtarı: <code>(name, type, id)</code> stable tiebreak için id eklendi.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AccountsListService {

    private final CustomerService  customerService;
    private final SupplierService supplierService;

    /**
     * Sayfalı cari hesap listesi.
     *
     * @param cursorJson  null/boş → ilk sayfa
     * @param limit       sayfa boyutu (1..50, default 20)
     * @param filter      "all" | "customer" | "supplier" | "overdue"
     * @param query       isim içeren arama (case-insensitive); null = filter yok
     */
    @Transactional(readOnly = true)
    public PaginatedAccountsResponse list(String cursorJson, int limit, String filter, String query) {
        // Sprint 8 hot-fix v2: limit üst sınır 200 (KOBİ tenant'larda 100-200 müşteri tipik;
        // alfabetik sondaki "Z" harfi ilk yüklemede gelsin diye limit yeterince yüksek).
        // 200+ müşterili büyük tenant'lar için pagination zaten devreye girer.
        int effectiveLimit = Math.max(1, Math.min(200, limit));
        AccountsListCursor cursor = AccountsListCursor.decode(cursorJson);

        boolean includeCustomers = !"supplier".equalsIgnoreCase(filter);
        boolean includeSuppliers = !"customer".equalsIgnoreCase(filter);

        List<Map<String, Object>> all = new ArrayList<>();

        if (includeCustomers) {
            // CustomerRepository.search: q+isActive filter'ı backend'de uygular (isim+telefon+email)
            // EntityGraph(account) ile N+1 önlenmiş.
            List<Customer> customers = customerService.search(query, true);
            for (Customer c : customers) {
                all.add(mapCustomer(c));
            }
        }

        if (includeSuppliers) {
            // listSuppliers(pageable, isActive) — yüksek limit ile çek; query in-memory filtre
            // (sprint sonu: SupplierRepository'ye search() metodu ekle, daha verimli)
            int sweepSize = 1000;
            List<SupplierResponse> suppliers = supplierService
                    .listSuppliers(PageRequest.of(0, sweepSize), true)
                    .getContent();
            for (SupplierResponse s : suppliers) {
                Map<String, Object> m = mapSupplier(s);
                // Query filter (in-memory; supplier'da DB-side search yok)
                if (query != null && !query.isBlank()) {
                    String name = String.valueOf(m.get("name")).toLowerCase();
                    if (!name.contains(query.toLowerCase())) continue;
                }
                all.add(m);
            }
        }

        // Filter — overdue
        if ("overdue".equalsIgnoreCase(filter)) {
            all.removeIf(m -> !Boolean.TRUE.equals(m.get("hasOverdue")));
        }

        // Sırala (name asc, type asc, id asc)
        all.sort(Comparator
                .comparing((Map<String, Object> m) -> str(m.get("name")), Comparator.nullsLast(String::compareTo))
                .thenComparing(m -> str(m.get("type")), Comparator.nullsLast(String::compareTo))
                .thenComparing(m -> str(m.get("id")), Comparator.nullsLast(String::compareTo)));

        // Cursor sonrası kayıtları seç
        if (cursor != null) {
            all.removeIf(m -> !cursor.isBefore(str(m.get("name")), str(m.get("type")), str(m.get("id"))));
        }

        // Limit + nextCursor (limit+1 mantığı: extra varsa hasMore=true)
        boolean hasMore = all.size() > effectiveLimit;
        List<Map<String, Object>> page = hasMore
                ? new ArrayList<>(all.subList(0, effectiveLimit))
                : all;

        String nextCursorJson = null;
        if (hasMore && !page.isEmpty()) {
            Map<String, Object> last = page.get(page.size() - 1);
            AccountsListCursor next = new AccountsListCursor(
                    str(last.get("name")), str(last.get("type")), str(last.get("id")));
            nextCursorJson = next.encode();
        }

        log.debug("AccountsList: filter={}, q={}, returned={}, hasMore={}",
                filter, query, page.size(), hasMore);

        return PaginatedAccountsResponse.of(page, nextCursorJson);
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private static Map<String, Object> mapCustomer(Customer c) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", c.getId());
        m.put("name", c.getName());
        m.put("type", "CUSTOMER");

        CustomerAccount acct = c.getAccount();
        BigDecimal currentBalance = acct != null ? acct.getCurrentBalance() : BigDecimal.ZERO;
        BigDecimal overdueAmount = acct != null ? acct.getOverdueAmount() : BigDecimal.ZERO;
        m.put("currentBalance", currentBalance != null ? currentBalance : BigDecimal.ZERO);
        m.put("overdueAmount", overdueAmount != null ? overdueAmount : BigDecimal.ZERO);
        m.put("hasOverdue", overdueAmount != null && overdueAmount.compareTo(BigDecimal.ZERO) > 0);
        return m;
    }

    private static Map<String, Object> mapSupplier(SupplierResponse s) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", s.getId());
        m.put("name", s.getName());
        m.put("type", "SUPPLIER");

        BigDecimal currentBalance = s.getCurrentBalance();
        BigDecimal overdueAmount = s.getOverdueAmount();
        m.put("currentBalance", currentBalance != null ? currentBalance : BigDecimal.ZERO);
        m.put("overdueAmount", overdueAmount != null ? overdueAmount : BigDecimal.ZERO);
        m.put("hasOverdue", overdueAmount != null && overdueAmount.compareTo(BigDecimal.ZERO) > 0);
        return m;
    }

    private static String str(Object o) {
        return o == null ? null : o.toString();
    }
}
