package com.sedcore.product.service.impl.invoice;

import lombok.extern.slf4j.Slf4j;

import java.util.*;
import java.util.regex.*;

/**
 * {@link TableRow} nesnesini {@link ParsedLine}'a dönüştürür.
 *
 * <p>Dönüşüm stratejisi:
 * <ol>
 *   <li>Başlık satırından her hücrenin {@link ColumnType}'ı ve X aralığı belirlenir.</li>
 *   <li>Veri satırındaki her hücre, başlık hücrelerinin X merkezine en yakın eşleşmeyle
 *       {@link ColumnType}'a atanır.</li>
 *   <li>Atanan sütun içeriğine göre sayısal değerler parse edilir.</li>
 * </ol>
 *
 * <p>Başlık satırı olmadan da çalışabilir (kolumnsuz mod):
 * {@link #parseWithoutHeader(TableRow)} metodu sütun sırasına göre heuristic atama yapar.
 */
@Slf4j
public class TableRowParser {

    // Bölge bazlı eşleme: her sütun, X ekseni üzerinde bir bölge "sahiplenir".
    // Sütun bölgesi: bu_sütun.xStart'tan sonraki_sütun.xStart'a kadar.
    // Son sütun sonsuz sağa uzanır. Veri hücresinin xStart'ı hangi bölgedeyse oraya atanır.
    // Ek tolerans: veri hücresi xStart'ı bölgenin soluna bu kadar taşabilir (resim boşluğu vb.)
    private static final float LEFT_OVERHANG_TOLERANCE = 40.0f;

    private static final Pattern NUMBER_PATTERN =
            Pattern.compile("(\\d{1,8}(?:[.,]\\d{1,4})?)");

    // "ad" = adet kısaltması (Satış Notu, POS fişlerinde yaygın)
    private static final Pattern UNIT_PATTERN =
            Pattern.compile("\\b(ADET|ADT|AD|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\\b",
                    Pattern.CASE_INSENSITIVE);

    // %0 dahil tüm geçerli KDV oranlarını yakala (0, 1, 8, 10, 18, 20)
    private static final Pattern VAT_PATTERN = Pattern.compile(
            "(?:%\\s*(0|1|8|10|18|20)\\b|\\b(0|1|8|10|18|20)\\s*%)", Pattern.CASE_INSENSITIVE);

    private static final Pattern BARCODE_PATTERN =
            Pattern.compile("\\b(\\d{13})\\b");

    // ── Sütun eşleme modeli ───────────────────────────────────────────────────

    private record ColumnMapping(ColumnType type, float xStart, float xEnd) {
        float centerX() { return (xStart + xEnd) / 2f; }
    }

    private final List<ColumnMapping> columnMappings;
    private final boolean hasHeader;

    // ── Yapıcılar ─────────────────────────────────────────────────────────────

    /**
     * Başlık satırından sütun eşlemesi oluşturur.
     *
     * @param headerRow pozisyonel olarak çıkarılmış başlık {@link TableRow}
     */
    public TableRowParser(TableRow headerRow) {
        this.columnMappings = buildMappings(headerRow);
        this.hasHeader = !columnMappings.isEmpty();
        log.debug("TableRowParser: {} sütun eşlemesi kuruldu", columnMappings.size());
    }

    private List<ColumnMapping> buildMappings(TableRow headerRow) {
        List<ColumnMapping> mappings = new ArrayList<>();
        for (TableCell cell : headerRow.getCells()) {
            String text = cell.trimmedText();
            Set<ColumnType> detected = InvoiceHeaderDetector.detect(text);
            if (detected.isEmpty()) continue;

            // TOTAL için özel kural: en sağdaki sütun her zaman kazanır.
            // "İskonto Tutarı" değil, "Mal Hizmet Tutarı" gibi asıl toplam sütunu seçilir.
            // "Mal Hizmet Tutarı" → {DESCRIPTION, TOTAL}: önce TOTAL güncellenir,
            // ardından DESCRIPTION zaten eşlenmiş olduğu için atlanır.
            if (detected.contains(ColumnType.TOTAL)) {
                mappings.removeIf(m -> m.type() == ColumnType.TOTAL);
                mappings.add(new ColumnMapping(ColumnType.TOTAL, cell.xStart(), cell.xEnd()));
                log.debug("TableRowParser: TOTAL sütunu güncellendi → '{}' (x={})", text, cell.xStart());
            }

            // Non-TOTAL türler: detected set içinde ilk henüz eşlenmemiş türü al.
            // Birden fazla ColumnType eşleşirse (örn. "Birim Fiyat" → UNIT_PRICE + UNIT)
            // sadece ilk uygun tür işlenir — geri kalanlar o hücreye ait değildir.
            for (ColumnType type : detected) {
                if (type == ColumnType.TOTAL) continue; // yukarıda işlendi
                boolean alreadyMapped = mappings.stream().anyMatch(m -> m.type() == type);
                if (!alreadyMapped) {
                    mappings.add(new ColumnMapping(type, cell.xStart(), cell.xEnd()));
                    log.debug("TableRowParser: '{}' → {} (xStart={})", text, type, cell.xStart());
                    break; // Bu hücreden yalnızca bir non-TOTAL tür eşle
                }
            }
        }
        mappings.sort(Comparator.comparingDouble(ColumnMapping::xStart));
        return mappings;
    }

    /**
     * Sütun bölgelerini hesaplar: her sütun, kendi xStart'ından bir sonraki sütunun
     * xStart'ına kadar olan alanı "sahiplenir". Bu bölge bazlı yaklaşım, ürün resmi
     * gibi metin olmayan nesnelerin oluşturduğu X kaymalarını tolere eder.
     */
    private List<float[]> buildColumnRegions() {
        List<float[]> regions = new ArrayList<>();
        for (int i = 0; i < columnMappings.size(); i++) {
            float regionStart = columnMappings.get(i).xStart() - LEFT_OVERHANG_TOLERANCE;
            float regionEnd = (i + 1 < columnMappings.size())
                    ? columnMappings.get(i + 1).xStart()
                    : Float.MAX_VALUE;
            regions.add(new float[]{regionStart, regionEnd});
        }
        return regions;
    }

    // ── Ana parse metodu ──────────────────────────────────────────────────────

    /**
     * Veri satırını parse eder.
     *
     * @param dataRow tablo veri satırı
     * @return doldurulmuş {@link ParsedLine}; isim boşsa geçersiz kabul edilmeli
     */
    public ParsedLine parse(TableRow dataRow) {
        if (!hasHeader || columnMappings.isEmpty()) {
            return parseWithoutHeader(dataRow);
        }
        return parseWithHeader(dataRow);
    }

    // Satır başındaki sıra numarasını temizleyen regex:
    // "1 Ürün Adı", "1. Ürün", "01 Ürün", "1.2 Ürün" gibi desenleri temizler.
    // Sadece 1-3 basamaklı sayı, ardından nokta/boşluk → temizle.
    private static final Pattern ROW_NUMBER_PREFIX =
            Pattern.compile("^\\d{1,3}[.\\s]+");

    // ── Başlıklı mod ──────────────────────────────────────────────────────────

    private ParsedLine parseWithHeader(TableRow dataRow) {
        ParsedLine result = new ParsedLine();

        // Sütun bölgelerini hesapla (her eşlemede bir kez)
        List<float[]> regions = buildColumnRegions();

        // ROW_NUMBER sütunu eşlenmiş mi? (varsa o hücreyi description'dan çıkar)
        boolean hasRowNumberCol = columnMappings.stream()
                .anyMatch(m -> m.type() == ColumnType.ROW_NUMBER);

        // Her veri hücresini bölge bazlı kolon eşlemesine ata
        Map<ColumnType, List<String>> assigned = new EnumMap<>(ColumnType.class);
        for (TableCell cell : dataRow.getCells()) {
            ColumnMapping best = findColumnByRegion(cell, regions);
            if (best != null) {
                assigned.computeIfAbsent(best.type(), k -> new ArrayList<>())
                        .add(cell.trimmedText());
            }
        }

        // Ürün adı
        String desc = joinCells(assigned.get(ColumnType.DESCRIPTION));
        if (desc != null && !desc.isBlank()) {
            desc = desc.trim();
            // Sıra numarası sütunu ayrıca eşlenmemişse, description başındaki rakamı temizle
            // Örn: "1 Motor Yağı" → "Motor Yağı" (1 sıra nosunun description'a taşması)
            if (!hasRowNumberCol) {
                desc = ROW_NUMBER_PREFIX.matcher(desc).replaceFirst("").trim();
            }
            if (!desc.isBlank()) {
                result.name = desc.substring(0, Math.min(desc.length(), 200));
            }
        }

        // Kod (barkod / OEM)
        String code = joinCells(assigned.get(ColumnType.CODE));
        if (code != null && !code.isBlank()) {
            applyCode(result, code.trim());
        }

        // Miktar
        result.quantity = parseNumber(joinCells(assigned.get(ColumnType.QUANTITY)));

        // Birim fiyat
        result.unitPrice = parseNumber(joinCells(assigned.get(ColumnType.UNIT_PRICE)));

        // Toplam
        result.totalPrice = parseNumber(joinCells(assigned.get(ColumnType.TOTAL)));

        // Birim
        String unitStr = joinCells(assigned.get(ColumnType.UNIT));
        if (unitStr != null) {
            Matcher um = UNIT_PATTERN.matcher(unitStr);
            if (um.find()) {
                result.unit = um.group(1).toUpperCase();
            }
        }

        // KDV
        String vatStr = joinCells(assigned.get(ColumnType.VAT));
        if (vatStr != null) {
            Matcher vm = VAT_PATTERN.matcher(vatStr);
            if (vm.find()) {
                String g = vm.group(1) != null ? vm.group(1) : vm.group(2);
                try { result.vatRate = Double.parseDouble(g); }
                catch (NumberFormatException ignored) {}
            }
        }

        // Fallback: kod yoksa full text'ten barkod aramayı dene
        if (result.code == null) {
            Matcher bm = BARCODE_PATTERN.matcher(dataRow.fullText());
            if (bm.find()) {
                result.code = bm.group(1);
                result.codeType = "BARCODE";
            }
        }

        return result;
    }

    /**
     * Bölge bazlı kolon eşleşmesi.
     *
     * <p>Her sütun, kendi X başlangıcından bir sonraki sütunun X başlangıcına kadar olan
     * bölgeyi "sahiplenir". Veri hücresinin {@code xStart} değeri hangi bölgeye düşüyorsa
     * o kolona atanır. {@code LEFT_OVERHANG_TOLERANCE} soldan taşmayı tolere eder —
     * ürün resmi gibi metin olmayan nesnelerin oluşturduğu X kaymasını karşılar.
     */
    private ColumnMapping findColumnByRegion(TableCell cell, List<float[]> regions) {
        if (columnMappings.isEmpty() || regions.isEmpty()) return null;
        float xStart = cell.xStart();

        for (int i = 0; i < regions.size(); i++) {
            float regionStart = regions.get(i)[0]; // xStart - LEFT_OVERHANG_TOLERANCE
            float regionEnd   = regions.get(i)[1]; // bir sonraki sütunun xStart'ı
            if (xStart >= regionStart && xStart < regionEnd) {
                return columnMappings.get(i);
            }
        }
        // Eşleşme yoksa: en sağ sütunun sağına düşen hücreler son sütuna verilir
        // (sayfa sonu toplam sütunu için tolerans)
        if (xStart >= regions.get(regions.size() - 1)[0]) {
            return columnMappings.get(columnMappings.size() - 1);
        }
        return null;
    }

    // ── Başlıksız mod (heuristic) ─────────────────────────────────────────────

    /**
     * Başlık yoksa sütun sırasına göre heuristic atama:
     * İlk büyük metin hücresi → açıklama, sayılar → miktar/fiyat.
     *
     * <p>Önemli: Satırın ilk hücresi tek küçük tam sayı ise (1-99) büyük ihtimalle
     * sıra numarasıdır — description veya quantity olarak kullanılmaz, atlanır.
     */
    private ParsedLine parseWithoutHeader(TableRow dataRow) {
        ParsedLine result = new ParsedLine();
        List<Double> numbers = new ArrayList<>();
        List<TableCell> cells = dataRow.getCells();

        for (int cellIdx = 0; cellIdx < cells.size(); cellIdx++) {
            TableCell cell = cells.get(cellIdx);
            String text = cell.trimmedText();
            if (text.isBlank()) continue;

            // İlk hücre tek küçük tam sayı → büyük ihtimalle sıra no, atla
            if (cellIdx == 0 && text.matches("\\d{1,3}") && result.name == null) {
                double v = Double.parseDouble(text);
                if (v >= 1 && v <= 999) {
                    continue; // sıra no olarak atla
                }
            }

            // Barkod testi (13 rakam)
            if (BARCODE_PATTERN.matcher(text).matches()) {
                result.code = text;
                result.codeType = "BARCODE";
                continue;
            }

            // Birim (tam eşleşme)
            Matcher um = UNIT_PATTERN.matcher(text);
            if (um.matches()) {
                result.unit = um.group(1).toUpperCase();
                continue;
            }

            // Saf sayısal hücre
            Double num = parseNumber(text);
            if (num != null && text.replaceAll("[0-9.,\\s]", "").isBlank()) {
                numbers.add(num);
                continue;
            }

            // Metin → açıklama (harf içeriyorsa)
            if (result.name == null && text.length() >= 3 &&
                    text.matches(".*[a-zA-ZğüşıöçĞÜŞİÖÇ].*")) {
                result.name = text.substring(0, Math.min(text.length(), 200));
            }
        }

        // Sayıları miktar/fiyat/toplam olarak ata
        if (!numbers.isEmpty()) {
            // Tam sayı, küçük değer (1-9999) → miktar adayı
            for (Double n : numbers) {
                if (n == Math.floor(n) && n >= 1 && n <= 9999 && result.quantity == null) {
                    result.quantity = n;
                    break;
                }
            }
            // Kalan sayılar fiyat/toplam
            List<Double> prices = numbers.stream()
                    .filter(n -> !n.equals(result.quantity))
                    .sorted()
                    .toList();
            if (!prices.isEmpty()) {
                result.unitPrice = prices.get(0);
            }
            if (prices.size() >= 2) {
                result.totalPrice = prices.get(prices.size() - 1);
            }
        }

        return result;
    }

    // ── Yardımcı metodlar ─────────────────────────────────────────────────────

    private void applyCode(ParsedLine result, String code) {
        if (code.matches("\\d{13}")) {
            result.code = code;
            result.codeType = "BARCODE";
        } else if (code.length() >= 4 &&
                   code.matches(".*[A-Za-z].*") && code.matches(".*[0-9].*")) {
            result.code = code.toUpperCase();
            result.codeType = "OEM";
        } else {
            result.code = code;
            result.codeType = "OEM";
        }
    }

    private String joinCells(List<String> cells) {
        if (cells == null || cells.isEmpty()) return null;
        return String.join(" ", cells).trim();
    }

    private Double parseNumber(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String normalized = raw.replaceAll("(\\d)\\.(\\d{3})", "$1$2").replace(",", ".");
        Matcher m = NUMBER_PATTERN.matcher(normalized);
        if (m.find()) {
            try {
                double val = Double.parseDouble(m.group(1));
                return val > 0 ? val : null;
            } catch (NumberFormatException ignored) {}
        }
        return null;
    }
}
