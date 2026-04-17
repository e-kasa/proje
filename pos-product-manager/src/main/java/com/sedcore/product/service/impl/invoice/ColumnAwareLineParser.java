package com.sedcore.product.service.impl.invoice;

import java.util.regex.*;

/**
 * Sütun pozisyon bilgisi kullanarak veri satırından alanları çıkarır.
 *
 * ColumnPositionMapper'dan alınan sütun sınırlarına göre
 * her alanı substring olarak çıkarır ve tip dönüşümü yapar.
 */
public class ColumnAwareLineParser {

    private static final Pattern NUMBER_PATTERN =
            Pattern.compile("(\\d{1,8}(?:[.,]\\d{1,4})?)");

    private static final Pattern UNIT_PATTERN =
            Pattern.compile("\\b(ADET|ADT|AD|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\\b",
                    Pattern.CASE_INSENSITIVE);

    // %0 (KDV muaf) dahil tüm geçerli KDV oranları
    private static final Pattern VAT_PATTERN = Pattern.compile(
            "(?:%\\s*(0|1|8|10|18|20)\\b|\\b(0|1|8|10|18|20)\\s*%)", Pattern.CASE_INSENSITIVE);

    // Satır başındaki sıra numarası: "1 ", "2. " gibi ön ekler
    private static final java.util.regex.Pattern ROW_NUM_PREFIX =
            java.util.regex.Pattern.compile("^\\d{1,3}[.\\s]+");

    private final ColumnPositionMapper mapper;

    public ColumnAwareLineParser(ColumnPositionMapper mapper) {
        this.mapper = mapper;
    }

    /**
     * Veri satırını parse eder, ColumnPositionMapper kullanarak alanları çıkarır.
     */
    public ParsedLine parse(String dataLine) {
        ParsedLine result = new ParsedLine();

        // Ürün adı — sıra numarası prefix'i temizle
        String desc = mapper.extract(dataLine, ColumnType.DESCRIPTION);
        if (desc != null && !desc.isBlank()) {
            desc = ROW_NUM_PREFIX.matcher(desc.trim()).replaceFirst("").trim();
            if (!desc.isBlank()) result.name = desc.substring(0, Math.min(desc.length(), 200));
        }

        // Ürün kodu
        String code = mapper.extract(dataLine, ColumnType.CODE);
        if (code != null && !code.isBlank()) {
            code = code.trim();
            if (code.matches("\\d{13}")) {
                result.code = code;
                result.codeType = "BARCODE";
            } else if (code.matches("[A-Z0-9][A-Z0-9 .\\-]{2,18}[A-Z0-9]") &&
                    code.matches(".*[A-Z].*") && code.matches(".*[0-9].*")) {
                result.code = code;
                result.codeType = "OEM";
            } else {
                result.code = code;
                result.codeType = "OEM";
            }
        }

        // Miktar
        String qtyStr = mapper.extract(dataLine, ColumnType.QUANTITY);
        result.quantity = parseNumber(qtyStr);

        // Birim fiyat
        String priceStr = mapper.extract(dataLine, ColumnType.UNIT_PRICE);
        result.unitPrice = parseNumber(priceStr);

        // Toplam
        String totalStr = mapper.extract(dataLine, ColumnType.TOTAL);
        result.totalPrice = parseNumber(totalStr);

        // Birim
        String unitStr = mapper.extract(dataLine, ColumnType.UNIT);
        if (unitStr != null) {
            Matcher um = UNIT_PATTERN.matcher(unitStr);
            if (um.find()) result.unit = um.group(1).toUpperCase();
        }

        // KDV oranı
        String vatStr = mapper.extract(dataLine, ColumnType.VAT);
        if (vatStr != null) {
            Matcher vm = VAT_PATTERN.matcher(vatStr);
            if (vm.find()) {
                try {
                    String vatGroup = vm.group(1) != null ? vm.group(1) : vm.group(2);
                    result.vatRate = Double.parseDouble(vatGroup);
                } catch (NumberFormatException ignored) {}
            }
        }

        return result;
    }

    private Double parseNumber(String raw) {
        if (raw == null || raw.isBlank()) return null;
        // Türkçe format: 1.234,56 → 1234.56
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
