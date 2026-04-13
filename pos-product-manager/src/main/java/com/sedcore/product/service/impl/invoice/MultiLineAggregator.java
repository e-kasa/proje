package com.sedcore.product.service.impl.invoice;

import java.util.ArrayList;
import java.util.List;

/**
 * Çok satırlı ürün girişlerini tek satırda birleştirir.
 *
 * Bazı faturalarda ürün adı birden fazla satıra yayılabilir.
 * Bu sınıf, miktar/fiyat içermeyen satırları bir önceki satırın
 * ürün adına ekler (max 3 satır birleştirme).
 *
 * Durum makinesi: IDLE → PENDING (incomplete satır) → tamamlandığında IDLE
 */
public class MultiLineAggregator {

    private enum State { IDLE, PENDING }

    private State state = State.IDLE;
    private ParsedLine pending = null;
    private int pendingLineCount = 0;
    private static final int MAX_MERGE_LINES = 3;

    /**
     * Satırı işler. Eğer önceki satırla birleştirilmesi gerekiyorsa bekletir.
     *
     * @param line Parse edilmiş satır
     * @return Tamamlanmış ParsedLine listesi (boş olabilir — bekletiliyor)
     */
    public List<ParsedLine> process(ParsedLine line) {
        List<ParsedLine> output = new ArrayList<>();

        if (isIncomplete(line)) {
            // Satırda miktar veya fiyat yok — bir sonraki satırla birleştirilecek
            if (state == State.PENDING && pendingLineCount < MAX_MERGE_LINES) {
                // Önceki pending satırın adına ekle
                if (pending.name != null && line.name != null) {
                    pending.name = pending.name + " " + line.name;
                }
                pendingLineCount++;
            } else {
                // Yeni pending başlat — öncekini yayınla
                if (state == State.PENDING && pending != null) {
                    output.add(pending);
                }
                pending = line;
                pendingLineCount = 1;
                state = State.PENDING;
            }
        } else {
            // Tam satır (miktar veya fiyat var)
            if (state == State.PENDING && pending != null) {
                // Pending satırı tamamla: eksik alanları bu satırdan al
                if (pending.quantity == null) pending.quantity = line.quantity;
                if (pending.unitPrice == null) pending.unitPrice = line.unitPrice;
                if (pending.code == null) pending.code = line.code;
                if (pending.code == null) pending.codeType = line.codeType;
                if (pending.unit == null) pending.unit = line.unit;
                if (pending.vatRate == null) pending.vatRate = line.vatRate;
                if (pending.totalPrice == null) pending.totalPrice = line.totalPrice;
                output.add(pending);
                pending = null;
                pendingLineCount = 0;
                state = State.IDLE;
            } else {
                output.add(line);
            }
        }

        return output;
    }

    /**
     * Tüm satırlar işlendikten sonra kalan pending satırı yayınla.
     */
    public List<ParsedLine> flush() {
        List<ParsedLine> output = new ArrayList<>();
        if (state == State.PENDING && pending != null) {
            output.add(pending);
            pending = null;
            pendingLineCount = 0;
            state = State.IDLE;
        }
        return output;
    }

    /** Satırda miktar ve fiyat ikisi de yoksa "incomplete" sayılır. */
    private boolean isIncomplete(ParsedLine line) {
        return line.quantity == null && line.unitPrice == null;
    }
}
