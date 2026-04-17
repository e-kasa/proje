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

    /**
     * Aynı metin satırında sayılmak için Y farkı toleransı (pt).
     * 4pt → 3.9pt Y farkına kadar aynı satır sayılır.
     * Önceki 3.0f ile Math.round() kullanımı tutarsız bucket'lara yol açıyordu.
     */
    private static final float ROW_Y_TOLERANCE = 4.0f;

    /** Aynı hücre içinde sayılmak için maksimum fragment boşluğu (pt). */
    private static final float WORD_GAP = 6.0f;

    /**
     * Yeni hücre başlangıcı için minimum boşluk (pt).
     * 12pt → GİB e-Arşiv gibi 10 sütunlu yoğun tablolarda "Sıra" ve "Mal Hizmet"
     * arasındaki dar boşluğu (≈12pt) doğru böler; 18pt ile bunlar tek hücreye birleşiyordu.
     */
    private static final float COLUMN_GAP = 12.0f;

    /**
     * Kesin footer satırları — tek başına veya çok kelimeli ama ürün adında çıkması imkânsız.
     * startsWith() ile eşleşir → hemen footer kabul edilir.
     */
    private static final Set<String> SPECIFIC_FOOTER_PREFIXES = Set.of(
            "genel toplam", "ara toplam", "kdv toplam", "kdv matrah", "vergi toplam",
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

    /**
     * Belirsiz footer kelimeleri — ürün adında da geçebilir.
     * Örnek: "Toplam Koru Yağı" ürün, "Toplam 1.234,56" footer.
     * Kural: kelimeden sonra harf geliyorsa ürün adı → footer DEĞİL.
     */
    private static final Set<String> AMBIGUOUS_FOOTER_WORDS = Set.of(
            "toplam", "total", "subtotal", "grand total"
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

            // Satırları oluştur (Y büyükten küçüğe = görsel üstten alta — standart PDF)
            List<TableRow> allRows = buildRows(rowBuckets);
            if (allRows.isEmpty()) {
                return Optional.empty();
            }

            // Başlık satırını bul
            int headerIdx = findHeaderRow(allRows);

            // ── Y koordinat yönü düzeltmesi ──────────────────────────────────
            // Bazı PDF üreticileri (HTML→PDF, web muhasebe sistemleri, POS yazılımları vb.)
            // ekran koordinat sistemini kullanır: Y=0 sol-üst, aşağıya doğru artar.
            // Bu durumda TreeMap(reverseOrder()) sayfayı ALT→ÜST sıralar:
            //   allRows[0] = sayfa altı (footer), ..., allRows[son] = sayfa üstü
            // Sonuç: başlık satırı listenin ortasından sonra bulunur;
            //        başlık "sonrası" data olarak üst-sayfa (başlık öncesi) içerik gelir.
            //
            // Tespit: başlık listenin %50'sinden sonra → Y ters → listeyi ters çevir.
            if (headerIdx < 0 || (allRows.size() > 4 && headerIdx > allRows.size() / 2)) {
                List<TableRow> reversed = new ArrayList<>(allRows);
                Collections.reverse(reversed);
                int revIdx = findHeaderRow(reversed);
                boolean reversedIsBetter = revIdx >= 0 && (headerIdx < 0 || revIdx < headerIdx);
                if (reversedIsBetter) {
                    allRows = reversed;
                    headerIdx = revIdx;
                    log.debug("PositionalTableExtractor: Ters Y koordinatı tespit edildi — " +
                              "sıra düzeltildi (başlık: {}/{})", headerIdx, allRows.size());
                }
            }

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
     *
     * <p>Bucket key = floor(y / ROW_Y_TOLERANCE).
     * Floor tabanlı bölme tutarlı bucket sınırları verir; önceki Math.round() yaklaşımı
     * bitişik Y değerlerini farklı bucket'lara düşürüyordu (örn: 10.4 → 9, 10.5 → 12).
     * TreeMap ters sıra → büyük bucket = görsel üst = ilk satır.
     */
    private static TreeMap<Integer, List<TextFragment>> groupByRow(List<TextFragment> fragments) {
        TreeMap<Integer, List<TextFragment>> map = new TreeMap<>(Comparator.reverseOrder());
        for (TextFragment f : fragments) {
            // Floor tabanlı bucket: [0, 4) → 0, [4, 8) → 1, vb.
            int bucket = (int)(f.y() / ROW_Y_TOLERANCE);
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

    /**
     * Başlık satırını arar. Önce katı eşleme (≥3 kolon), bulunamazsa
     * gevşek eşleme (≥2 kolon) ile tekrar dener.
     */
    private static int findHeaderRow(List<TableRow> rows) {
        // 1. Katı eşleme: ≥3 sütun tipi
        for (int i = 0; i < rows.size(); i++) {
            if (InvoiceHeaderDetector.isHeader(rows.get(i).fullText())) {
                return i;
            }
        }
        // 2. Gevşek eşleme: ≥2 sütun tipi (sade fatura formatları için)
        log.debug("PositionalTableExtractor: Katı başlık bulunamadı — gevşek mod deneniyor");
        for (int i = 0; i < rows.size(); i++) {
            if (InvoiceHeaderDetector.isHeaderRelaxed(rows.get(i).fullText())) {
                log.debug("PositionalTableExtractor: Gevşek başlık → satır {}: '{}'",
                        i, rows.get(i).fullText());
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
        String lower = text.toLowerCase().trim();

        // 1. Kesin footer prefix'leri — her zaman durdur
        for (String prefix : SPECIFIC_FOOTER_PREFIXES) {
            if (lower.startsWith(prefix)) return true;
        }

        // 2. Belirsiz kelimeler — sonrasında harf varsa ürün adı, footer değil
        //    "Toplam Koru Yağı" → harf var → ürün  ✓
        //    "Toplam 1.234,56"  → harf yok → footer ✓
        //    "Toplam"           → boş → footer ✓
        for (String word : AMBIGUOUS_FOOTER_WORDS) {
            if (lower.startsWith(word)) {
                String remainder = lower.substring(word.length()).trim();
                if (remainder.isEmpty() || !Character.isLetter(remainder.charAt(0))) {
                    return true;
                }
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
