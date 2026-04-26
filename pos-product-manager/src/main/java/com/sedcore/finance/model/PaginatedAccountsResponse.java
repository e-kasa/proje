package com.sedcore.finance.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * Sprint 8 B0 — Sayfalı cari hesap listesi yanıtı.
 *
 * <ul>
 *   <li><b>items</b>: Her bir cari için map ({@code id, name, type, currentBalance, hasOverdue, ...}).
 *       Sıralı (name asc, type asc, id asc).</li>
 *   <li><b>nextCursor</b>: Bir sonraki sayfa için cursor (JSON). null = son sayfa.</li>
 *   <li><b>hasMore</b>: nextCursor != null shorthand.</li>
 * </ul>
 *
 * Toplam sayım (total) opsiyonel — büyük listede COUNT pahalı, hesaplanmaz.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaginatedAccountsResponse {

    private List<Map<String, Object>> items;
    private String nextCursor;
    private boolean hasMore;

    public static PaginatedAccountsResponse of(List<Map<String, Object>> items, String nextCursor) {
        return PaginatedAccountsResponse.builder()
                .items(items)
                .nextCursor(nextCursor)
                .hasMore(nextCursor != null)
                .build();
    }
}
