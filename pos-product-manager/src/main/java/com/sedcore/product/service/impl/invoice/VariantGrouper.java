package com.sedcore.product.service.impl.invoice;

import lombok.extern.slf4j.Slf4j;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Faturadan çıkarılan {@link ParsedLine} listesini varyant gruplarına ayırır.
 *
 * <h3>Durum 1 — Tek satır (toplam miktar)</h3>
 * <pre>
 *   Beymen Fermuarlı Modal  │  28 ad  │  400₺
 * </pre>
 * → Beden/renk bilgisi yok → tekil ürün, {@link VariantGroup#isGroup()} = false
 *
 * <h3>Durum 2 — Her varyant ayrı satır</h3>
 * <pre>
 *   Beymen Fermuarlı Modal S   │  5 ad  │  400₺
 *   Beymen Fermuarlı Modal M   │  8 ad  │  400₺
 *   Beymen Fermuarlı Modal L   │ 10 ad  │  400₺
 *   Beymen Fermuarlı Modal XL  │  5 ad  │  400₺
 * </pre>
 * → Ardışık satırlar, aynı base isim, aynı fiyat → 1 grup, 4 varyant satırı
 *
 * <h3>Tespit mantığı</h3>
 * <ol>
 *   <li>Her satırın ürün adının sonundan bilinen beden/renk değeri çıkarılmaya çalışılır.</li>
 *   <li>Ardışık satırlar aynı normalize edilmiş base isim + yakın fiyat → grup adayı.</li>
 *   <li>Grupta ≥ 2 satır → {@link VariantGroup} (Durum 2). 1 satır → tekil (Durum 1).</li>
 * </ol>
 */
@Slf4j
public class VariantGrouper {

    // ── Bilinen beden değerleri ───────────────────────────────────────────────

    private static final Set<String> SIZE_VALUES = new HashSet<>(Arrays.asList(
            // Tekstil
            "xs", "s", "m", "l", "xl", "xxl", "xxxl", "2xl", "3xl", "4xl", "5xl",
            "s/m", "m/l", "l/xl",
            // Ayakkabı (35-47)
            "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47",
            // Çocuk beden
            "2", "4", "6", "8", "10", "12", "14",
            // Alternatif yazım
            "small", "medium", "large", "x-large", "xx-large"
    ));

    // ── Bilinen renk değerleri (TR + EN) ──────────────────────────────────────

    private static final Set<String> COLOR_VALUES = new HashSet<>(Arrays.asList(
            // Türkçe
            "siyah", "beyaz", "kırmızı", "kirmizi", "mavi", "lacivert",
            "yeşil", "yesil", "sarı", "sari", "turuncu", "mor", "pembe",
            "gri", "kahverengi", "kahve", "haki", "bordo", "ekru", "krem",
            "bej", "antrasit", "şampanya", "sampanya", "vizon", "hardal",
            "mint", "lila", "indigo", "camel", "kiremit", "nakış", "nakis",
            // İngilizce
            "black", "white", "red", "blue", "navy", "green", "yellow",
            "orange", "purple", "pink", "grey", "gray", "brown", "beige",
            "khaki", "ivory", "cream", "coral", "teal", "maroon", "olive",
            "cyan", "magenta", "lilac", "lavender", "gold", "silver"
    ));

    // ── Fiyat toleransı (%2 veya max 1 TL) ───────────────────────────────────
    private static final double PRICE_TOLERANCE_PCT = 0.02;
    private static final double PRICE_TOLERANCE_ABS = 1.0;

    // ── Bir grupta izin verilen maksimum varyant satırı ───────────────────────
    private static final int MAX_GROUP_SIZE = 30;

    // ── Beden/renk suffix pattern (örn: " - XL", " / M", " (S)") ────────────
    private static final Pattern SUFFIX_PATTERN =
            Pattern.compile("[\\s\\-/|()\\[\\]]+([A-Za-z0-9ğüşıöçĞÜŞİÖÇ]+)\\s*$");

    // ── Veri modelleri ────────────────────────────────────────────────────────

    /**
     * Bir varyant satırı: orijinal {@link ParsedLine} + çıkarılan özellik bilgisi.
     */
    public record VariantLine(
            ParsedLine line,
            String attributeValue,
            String attributeType
    ) {}

    /**
     * Gruplama sonucu: base satır + varsa varyant alt satırları.
     *
     * <p>{@code variants} boş ise tekil ürün (Durum 1).
     * {@code variants} dolu ise varyant grubu (Durum 2).
     */
    public record VariantGroup(
            ParsedLine base,
            List<VariantLine> variants
    ) {
        /** Grup mu? (≥ 2 varyant satırı) */
        public boolean isGroup() {
            return variants != null && !variants.isEmpty();
        }
    }

    // ── Ana gruplama metodu ───────────────────────────────────────────────────

    /**
     * Parsed satır listesini varyant gruplarına böler.
     *
     * @param lines ham parse edilmiş satırlar
     * @return gruplanmış sonuçlar
     */
    public static List<VariantGroup> group(List<ParsedLine> lines) {
        if (lines == null || lines.isEmpty()) {
            return Collections.emptyList();
        }

        // Her satırı özellik bilgisiyle etiketle
        List<AnnotatedLine> annotated = lines.stream()
                .map(l -> new AnnotatedLine(l, detectAttribute(l.name)))
                .toList();

        List<VariantGroup> result = new ArrayList<>();
        int i = 0;

        while (i < annotated.size()) {
            AnnotatedLine current = annotated.get(i);

            // Özellik yok → tekil ürün (Durum 1)
            if (current.attr == null) {
                result.add(new VariantGroup(current.line, Collections.emptyList()));
                i++;
                continue;
            }

            String baseName = current.baseName();
            Double basePrice = current.line.unitPrice;

            // Aynı base isimli + yakın fiyatlı ardışık satırları topla
            List<AnnotatedLine> groupLines = new ArrayList<>();
            groupLines.add(current);

            int j = i + 1;
            while (j < annotated.size() && j - i < MAX_GROUP_SIZE) {
                AnnotatedLine next = annotated.get(j);
                if (next.attr == null) break;

                String nextBase = next.baseName();
                if (!isSameBase(baseName, nextBase)) break;
                if (!isPriceSimilar(basePrice, next.line.unitPrice)) break;

                groupLines.add(next);
                j++;
            }

            if (groupLines.size() >= 2) {
                // Durum 2: varyant grubu
                List<VariantLine> variantLines = groupLines.stream()
                        .map(al -> new VariantLine(al.line, al.attr.value(), al.attr.type()))
                        .toList();

                ParsedLine baseLine = buildBaseLine(baseName, variantLines, basePrice);
                result.add(new VariantGroup(baseLine, variantLines));
                log.debug("VariantGrouper: '{}' için {} varyant grubu oluşturuldu",
                        baseName, variantLines.size());
                i = j;
            } else {
                // Tek satır (özellik tespit edildi ama grup oluşmadı) → tekil
                result.add(new VariantGroup(current.line, Collections.emptyList()));
                i++;
            }
        }

        return result;
    }

    // ── Özellik tespiti ───────────────────────────────────────────────────────

    private record Attribute(String value, String type) {}

    /**
     * Ürün adının sonundan beden veya renk değeri çıkarmaya çalışır.
     * Başarısız olursa {@code null} döner.
     */
    static Attribute detectAttribute(String name) {
        if (name == null || name.isBlank()) return null;

        String trimmed = name.trim();
        Matcher m = SUFFIX_PATTERN.matcher(trimmed);
        if (!m.find()) return null;

        String candidate = m.group(1).toLowerCase();

        if (SIZE_VALUES.contains(candidate)) {
            return new Attribute(m.group(1).toUpperCase(), "SIZE");
        }
        if (COLOR_VALUES.contains(candidate)) {
            String capitalized = Character.toUpperCase(m.group(1).charAt(0))
                    + m.group(1).substring(1).toLowerCase();
            return new Attribute(capitalized, "COLOR");
        }
        return null;
    }

    /**
     * Ürün adından özellik değerini çıkararak base adı döner.
     * Örn: "Beymen Modal XL" → "Beymen Modal"
     */
    static String extractBaseName(String name, Attribute attr) {
        if (attr == null || name == null) return name;
        Matcher m = SUFFIX_PATTERN.matcher(name.trim());
        if (m.find() && m.group(1).equalsIgnoreCase(attr.value())) {
            return name.substring(0, m.start()).trim();
        }
        return name.trim();
    }

    // ── Yardımcı metodlar ─────────────────────────────────────────────────────

    private static boolean isSameBase(String a, String b) {
        if (a == null || b == null) return false;
        return a.equalsIgnoreCase(b);
    }

    private static boolean isPriceSimilar(Double a, Double b) {
        if (a == null || b == null) return true; // biri yoksa fiyat kontrolü yapma
        double diff = Math.abs(a - b);
        double pctDiff = a > 0 ? diff / a : diff;
        return diff <= PRICE_TOLERANCE_ABS || pctDiff <= PRICE_TOLERANCE_PCT;
    }

    /**
     * Varyant satırlarını temsil eden özet base {@link ParsedLine} oluşturur.
     * Miktar: tüm varyantların toplamı. İsim: normalize base isim. Fiyat: ilk varyanttan.
     */
    private static ParsedLine buildBaseLine(
            String baseName, List<VariantLine> variants, Double price) {
        ParsedLine base = new ParsedLine();
        base.name = baseName;
        base.unitPrice = price;

        // Toplam miktar
        double totalQty = variants.stream()
                .mapToDouble(v -> v.line().quantity != null ? v.line().quantity : 1.0)
                .sum();
        base.quantity = totalQty;

        // İlk varyanttan code/unit/vatRate miras al
        ParsedLine first = variants.get(0).line();
        base.code = first.code;
        base.codeType = first.codeType;
        base.unit = first.unit;
        base.vatRate = first.vatRate;
        base.vatIncluded = first.vatIncluded;

        return base;
    }

    // ── İç sınıf: Etiketli satır ─────────────────────────────────────────────

    private static class AnnotatedLine {
        final ParsedLine line;
        final Attribute attr;
        final String _baseName;

        AnnotatedLine(ParsedLine line, Attribute attr) {
            this.line = line;
            this.attr = attr;
            this._baseName = (attr != null && line.name != null)
                    ? extractBaseName(line.name, attr).toLowerCase()
                    : (line.name != null ? line.name.toLowerCase() : "");
        }

        String baseName() {
            return _baseName;
        }
    }
}
