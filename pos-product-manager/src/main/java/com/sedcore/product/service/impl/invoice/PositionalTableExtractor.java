package com.sedcore.product.service.impl.invoice;

import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;

import java.io.IOException;
import java.util.*;

/**
 * PDFBox 3.x uyumlu, konum tabanlı tablo çıkarıcı.
 *
 * <p>Strateji:
 * <ol>
 *   <li>İç {@link FragmentCollector} sınıfı {@code writeString()} metodunu override ederek
 *       her karakter/parçanın X/Y koordinatını toplar.</li>
 *   <li>Fragment'lar Y koordinatına göre ({@value #ROW_Y_TOLERANCE} pt toleransla) satırlara
 *       gruplanır. PDF koordinat sistemi Y-yukarı olduğundan en büyük Y = görsel en üst satır;
 *       {@code TreeMap} ters sırayla tutulur.</li>
 *   <li>Her satırda bitişik fragment'lar {@value #WORD_GAP} pt boşluk eşiğiyle kelimelere,
 *       {@value #COLUMN_GAP} pt boşluk eşiğiyle hücrelere ayrılır.</li>
 *   <li>Başlık tespiti: {@link InvoiceHeaderDetector} ≥ 3 eşleşme bulduğu satır başlık satırı
 *       kabul edilir. Başlık öncesi satırlar (fatura başlığı, adres vb.) atılır.</li>
 *   <li>Tablo sonu: içerik satırlarındaki toplam/dipnot dedektörü tetiklenirse döngü kırılır.</li>
 * </ol>
 *
 * <p>Hata toleransı: Pozisyonel çıkarım başarısız olursa (hiç fragment bulunamazsa veya
 * başlık tespit edilemezse) {@code Optional.empty()} döner; çağıran {@code parsePdf()}
 * mevcut regex yoluna düşer.
 */
@Slf4j
public class PositionalTableExtractor {

    // ── Eşikler ───────────────────────────────────────────────────────────────

    /** Aynı metin satırında sayılmak için Y farkı toleransı (pt). */
    private static final float ROW_Y_TOLERANCE = 3.0f;

    /** Aynı hücre içinde sayılmak için maksimum fragment boşluğu (pt). */
    private static final float WORD_GAP = 6.0f;

    /** Yeni hücre başlangıcı için minimum boşluk (pt). */
    private static final float COLUMN_GAP = 18.0f;

    /** Tablo sonu olarak değerlendirilen satır başlangıçları (küçük harf). */
    private static final Set<String> FOOTER_PREFIXES = Set.of(
            "toplam", "genel toplam", "ara toplam", "subtotal", "total",
            "kdv toplam", "kdv matrah", "vergi toplam",
            "ödenecek", "odenecek", "net toplam",
            "iban", "banka", "hesap no", "açıklama:", "aciklama:",
            // e-Arşiv fatura özet satırları
            "mal hizmet toplam", "hesaplanan kdv", "vergiler dahil",
            "toplam iskonto", "toplam i̇skonto",
            // Satış notu dipnotları
            "güncel bakiye", "guncel bakiye",
            "teşekkür", "tesekkur",
            "yalnız", "yalniz",
            "fatura doğrulama", "fatura dogrulama",
            "mali i̇ade", "mali iade",
            "i̇ade edilen", "iade edilen",
            "hesap bilgileri",
            "e-arşiv", "e-arsiv"
    );

    // ── Sonuç modeli ─────────────────────────────────────────────────────────

    /**
     * Pozisyonel çıkarım sonucu: başlık satırı + ürün veri satırları.
     *
     * @param headerRow  başlık {@link TableRow} — {@link TableRowParser} için gerekli
     * @param dataRows   başlık sonrası temizlenmiş ürün veri satırları
     */
    public record ExtractionResult(TableRow headerRow, List<TableRow> dataRows) {}

    // ── Ana metod ─────────────────────────────────────────────────────────────

    /**
     * PDF dokümanından tablo satırlarını pozisyonel olarak çıkarır.
     *
     * @param doc yüklü {@link PDDocument}
     * @return başarılı ise {@link ExtractionResult}, başarısız ise {@code Optional.empty()}
     */
    public static Optional<ExtractionResult> extract(PDDocument doc) {
        try {
            FragmentCollector collector = new FragmentCollector();
            collector.setSortByPosition(true);
            collector.getText(doc); // fragment toplamak için çalıştır (çıktı kullanılmaz)

            List<TextFragment> fragments = collector.getFragments();
            if (fragments.isEmpty()) {
                log.debug("PositionalTableExtractor: Fragment bulunamadı — regex yoluna düşülüyor");
                return Optional.empty();
            }

            // Y koordinatına göre satırlara grupla
            TreeMap<Integer, List<TextFragment>> rowBuckets = groupByRow(fragments);

            // Satırları oluştur (Y büyükten küçüğe = görsel üstten alta)
            List<TableRow> allRows = buildRows(rowBuckets);
            if (allRows.isEmpty()) {
                return Optional.empty();
            }

            // Başlık satırını bul
            int headerIdx = findHeaderRow(allRows);
            if (headerIdx < 0) {
                log.debug("PositionalTableExtractor: Başlık satırı bulunamadı — regex yoluna düşülüyor");
                return Optional.empty();
            }

            TableRow headerRow = allRows.get(headerIdx);

            // Başlık sonrası satırları filtrele
            List<TableRow> dataRows = extractTableRows(allRows, headerIdx);
            log.info("PositionalTableExtractor: {} tablo satırı çıkarıldı (başlık indeksi: {})",
                    dataRows.size(), headerIdx);
            return Optional.of(new ExtractionResult(headerRow, dataRows));

        } catch (IOException e) {
            log.error("PositionalTableExtractor: PDF okuma hatası: {}", e.getMessage());
            return Optional.empty();
        }
    }

    // ── Fragment → Row gruplamasi ─────────────────────────────────────────────

    /**
     * Fragment'ları Y toleransına göre integer bucket'lara gruplar.
     * Bucket key = round(y / ROW_Y_TOLERANCE) * ROW_Y_TOLERANCE.
     * TreeMap ters sıra → büyük Y = görsel üst = ilk satır.
     */
    private static TreeMap<Integer, List<TextFragment>> groupByRow(List<TextFragment> fragments) {
        // Ters sıra: büyük Y değeri (görsel üst) → önce gelir
        TreeMap<Integer, List<TextFragment>> map = new TreeMap<>(Comparator.reverseOrder());
        for (TextFragment f : fragments) {
            int bucket = Math.round(f.y() / ROW_Y_TOLERANCE) * Math.round(ROW_Y_TOLERANCE);
            map.computeIfAbsent(bucket, k -> new ArrayList<>()).add(f);
        }
        return map;
    }

    // ── Row listesi oluştur ───────────────────────────────────────────────────

    private static List<TableRow> buildRows(TreeMap<Integer, List<TextFragment>> rowBuckets) {
        List<TableRow> rows = new ArrayList<>();
        for (Map.Entry<Integer, List<TextFragment>> entry : rowBuckets.entrySet()) {
            List<TextFragment> rowFragments = entry.getValue();
            // X'e göre sırala
            rowFragments.sort(Comparator.comparingDouble(TextFragment::x));

            List<TableCell> cells = buildCells(rowFragments);
            if (cells.isEmpty()) {
                continue;
            }
            float yCenter = entry.getKey();
            rows.add(new TableRow(yCenter, cells));
        }
        return rows;
    }

    /** Fragment listesinden hücre listesi oluştur (WORD_GAP / COLUMN_GAP eşikleriyle). */
    private static List<TableCell> buildCells(List<TextFragment> fragments) {
        List<TableCell> cells = new ArrayList<>();
        if (fragments.isEmpty()) {
            return cells;
        }

        StringBuilder cellText = new StringBuilder();
        float cellXStart = fragments.get(0).x();
        float prevXEnd = fragments.get(0).xEnd();

        for (int i = 0; i < fragments.size(); i++) {
            TextFragment f = fragments.get(i);
            if (i == 0) {
                cellText.append(f.text());
                continue;
            }

            float gap = f.x() - prevXEnd;
            if (gap >= COLUMN_GAP) {
                // Yeni hücre başlat
                String text = cellText.toString().trim();
                if (!text.isBlank()) {
                    cells.add(new TableCell(text, cellXStart, prevXEnd));
                }
                cellText = new StringBuilder(f.text());
                cellXStart = f.x();
            } else if (gap >= WORD_GAP) {
                // Aynı hücre içinde kelime boşluğu
                cellText.append(' ').append(f.text());
            } else {
                // Bitişik karakter
                cellText.append(f.text());
            }
            prevXEnd = f.xEnd();
        }

        // Son hücreyi ekle
        String lastText = cellText.toString().trim();
        if (!lastText.isBlank()) {
            cells.add(new TableCell(lastText, cellXStart, prevXEnd));
        }
        return cells;
    }

    // ── Başlık tespiti ────────────────────────────────────────────────────────

    private static int findHeaderRow(List<TableRow> rows) {
        // e-Arşiv fatura gibi karmaşık belgelerde başlık satırı 40-50. satırda olabilir.
        // Tüm satırları tara — ilk eşleşen başlık satırıdır.
        for (int i = 0; i < rows.size(); i++) {
            String fullText = rows.get(i).fullText();
            if (InvoiceHeaderDetector.isHeader(fullText)) {
                return i;
            }
        }
        return -1;
    }

    // ── Başlık sonrası tablo satırları ────────────────────────────────────────

    private static List<TableRow> extractTableRows(List<TableRow> allRows, int headerIdx) {
        List<TableRow> result = new ArrayList<>();
        for (int i = headerIdx + 1; i < allRows.size(); i++) {
            TableRow row = allRows.get(i);
            String text = row.fullText().trim();
            if (text.isBlank() || text.length() < 2) {
                continue;
            }
            if (isTableFooter(text)) {
                log.debug("PositionalTableExtractor: Tablo sonu satırı tespit edildi: '{}'", text);
                break;
            }
            result.add(row);
        }
        return result;
    }

    private static boolean isTableFooter(String text) {
        String lower = text.toLowerCase();
        for (String prefix : FOOTER_PREFIXES) {
            if (lower.startsWith(prefix)) {
                return true;
            }
        }
        return false;
    }

    // ── İç sınıf: FragmentCollector ──────────────────────────────────────────

    /**
     * PDFBox 3.x uyumlu fragment toplayıcı.
     * {@code writeString()} override'ı her karakter/kelime parçasının
     * X/Y koordinatını ve genişliğini {@link TextFragment} olarak saklar.
     */
    private static class FragmentCollector extends PDFTextStripper {

        private final List<TextFragment> fragments = new ArrayList<>();

        FragmentCollector() throws IOException {
            super();
        }

        @Override
        protected void writeString(String text, List<TextPosition> textPositions) throws IOException {
            // textPositions PDFBox tarafından görsel okuma sırasına göre sıralanmış gelir
            if (textPositions == null || textPositions.isEmpty()) {
                return;
            }
            // Her TextPosition bir karakter veya glif; grupları kelimeye birleştiriyoruz
            // ancak koordinat hassasiyeti için karakter bazında işliyoruz
            StringBuilder wordBuf = new StringBuilder();
            float wordX = 0f;
            float wordY = 0f;
            float wordWidth = 0f;

            for (TextPosition tp : textPositions) {
                String ch = tp.getUnicode();
                if (ch == null || ch.isEmpty()) {
                    continue;
                }
                // Görünmez karakter veya boşluk → kelimeyi bitir
                if (ch.isBlank()) {
                    if (wordBuf.length() > 0) {
                        fragments.add(new TextFragment(
                                wordBuf.toString(), wordX, wordY, wordWidth));
                        wordBuf.setLength(0);
                        wordWidth = 0f;
                    }
                    continue;
                }
                if (wordBuf.isEmpty()) {
                    wordX = tp.getX();
                    wordY = tp.getY();
                    wordWidth = 0f;
                }
                wordBuf.append(ch);
                wordWidth += tp.getWidthDirAdj();
            }
            // Kalan kelimeyi ekle
            if (wordBuf.length() > 0) {
                fragments.add(new TextFragment(
                        wordBuf.toString(), wordX, wordY, wordWidth));
            }
        }

        /**
         * PDFBox 3.x: yazma işlemi için null writer kullan
         * (çıktı String'e ihtiyacımız yok, sadece fragment topluyoruz).
         */
        @Override
        protected void writeLineSeparator() throws IOException {
            // No-op: çıktıya yazmıyoruz
        }

        @Override
        protected void writeParagraphSeparator() throws IOException {
            // No-op
        }

        /**
         * Writer erişimi yerine fragments listesi üzerinden çalışıyoruz;
         * super çağrısını null writer hatası almamak için geçersiz kılıyoruz.
         */
        @Override
        protected void writeString(String text) throws IOException {
            // Koordinatlı versiyon kullanıldığından bu metod boş bırakılır
        }

        List<TextFragment> getFragments() {
            return Collections.unmodifiableList(fragments);
        }
    }

    // PDFBox, getText() metodunu çağırdığında çıktıyı bir Writer'a yazmaya çalışır.
    // Fragment toplama amacıyla bu çıktıya ihtiyacımız yok ama NPE önlemek için
    // FragmentCollector'ı getText() çağrısından önce output writer'la başlatmak gerekebilir.
    // PDFBox 3.x getText() içeride StringWriter kullanır → sorun yok.
}
