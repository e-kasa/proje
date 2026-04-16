package com.sedcore.product.service.impl.invoice;

import java.util.Collections;
import java.util.List;
import java.util.StringJoiner;

/**
 * Pozisyonel çıkarımla elde edilmiş tek bir tablo satırını temsil eder.
 * Satır, aynı Y koordinat aralığında gruplanmış {@link TableCell}'lerden oluşur.
 */
public class TableRow {

    /** Satırın ortalama Y koordinatı (PDF koordinatı — büyük değer = görsel üst). */
    private final float yCenter;

    /** Soldaki hücreden sağdaki hücreye sıralı hücre listesi. */
    private final List<TableCell> cells;

    public TableRow(float yCenter, List<TableCell> cells) {
        this.yCenter = yCenter;
        this.cells = Collections.unmodifiableList(cells);
    }

    public float getYCenter() {
        return yCenter;
    }

    public List<TableCell> getCells() {
        return cells;
    }

    /** Tüm hücrelerin boşlukla birleştirilmiş tam metni. */
    public String fullText() {
        StringJoiner sj = new StringJoiner(" ");
        for (TableCell cell : cells) {
            String t = cell.trimmedText();
            if (!t.isBlank()) {
                sj.add(t);
            }
        }
        return sj.toString();
    }

    /**
     * Belirtilen indeksteki hücreyi döner; yoksa boş string içeren dummy hücre.
     */
    public TableCell cellAt(int index) {
        if (index < 0 || index >= cells.size()) {
            return new TableCell("", 0f, 0f);
        }
        return cells.get(index);
    }

    /** Belirtilen indeksteki hücrenin trim edilmiş metnini döner. */
    public String textAt(int index) {
        return cellAt(index).trimmedText();
    }

    @Override
    public String toString() {
        return "TableRow{y=" + yCenter + ", cells=" + cells + "}";
    }
}
