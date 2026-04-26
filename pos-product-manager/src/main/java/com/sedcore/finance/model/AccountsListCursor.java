package com.sedcore.finance.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sprint 8 B0 — Cari hesap liste cursor'u.
 *
 * <p>Transparent JSON format (kullanıcı kararı 2026-04-26): debug edilebilir,
 * base64 wrap yok. Sıralama anahtarı: <code>(name, type, id)</code> stable
 * tiebreak için id eklendi.
 *
 * <p>Format örneği:
 * <pre>{"name":"AHMET YILMAZ","type":"CUSTOMER","id":"cus-..."}</pre>
 *
 * <p>Boş cursor (ilk sayfa): null. Son sayfa sonrası: nextCursor = null.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountsListCursor {

    private String name;
    private String type;  // "CUSTOMER" | "SUPPLIER"
    private String id;

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** JSON string → AccountsListCursor. Null veya boş string → null döner. */
    public static AccountsListCursor decode(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return MAPPER.readValue(json, AccountsListCursor.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid cursor: " + json, e);
        }
    }

    /** AccountsListCursor → JSON string. */
    public String encode() {
        try {
            return MAPPER.writeValueAsString(this);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to encode cursor", e);
        }
    }

    /**
     * Bu cursor "kayıt"tan önce mi? (ilerleyiş kontrolü).
     * Tuple sıralaması: name asc, type asc, id asc.
     */
    public boolean isBefore(String otherName, String otherType, String otherId) {
        int n = compareNullSafe(this.name, otherName);
        if (n != 0) return n < 0;
        int t = compareNullSafe(this.type, otherType);
        if (t != 0) return t < 0;
        return compareNullSafe(this.id, otherId) < 0;
    }

    private static int compareNullSafe(String a, String b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
    }
}
