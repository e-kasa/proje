package com.sedcore.product.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.exception.BusinessException;
import com.sedcore.product.model.DocumentAnalyzeResponse;
import com.sedcore.product.model.DocumentItemResult;
import com.sedcore.product.repository.BarcodeRepository;
import com.sedcore.product.repository.ProductRepository;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.product.service.DocumentAnalyzeService;
import com.sedcore.product.service.impl.invoice.*;
import com.sedcore.autoparts.repository.OemNumberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;
import java.util.regex.*;
import java.util.stream.Collectors;

/**
 * Fatura/İrsaliye PDF + Görüntü analiz servisi.
 *
 * Akış (PDF):
 * 1. PDFBox ile PDF'ten metin çıkar
 * 2. InvoiceHeaderDetector → başlık var mı? → ColumnAwareLineParser / regex fallback
 * 3. MultiLineAggregator → çok satırlı ürün birleştirme
 * 4. Barkod → OEM → İsim sıralamasıyla sistemde eşleştir
 * 5. DocumentAnalyzeResponse döner
 *
 * Akış (Görüntü JPG/PNG):
 * 1. Python OCR servisine HTTP ile gönder → metin al
 * 2. Aynı metin parse mantığı
 */
@Service
@Slf4j
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DocumentAnalyzeServiceImpl implements DocumentAnalyzeService {

    private final BarcodeRepository barcodeRepository;
    private final OemNumberRepository oemNumberRepository;
    private final ProductRepository productRepository;
    private final ProductVariantRepository productVariantRepository;

    @Value("${ocr.service.url:http://localhost:8003}")
    private String ocrServiceUrl;

    // EAN13 barkod: tam olarak 13 rakam
    private static final Pattern BARCODE_PATTERN = Pattern.compile("\\b(\\d{13})\\b");
    // OEM: harf+rakam karışımı, 4-20 karakter (boşluk/tire içerebilir)
    private static final Pattern OEM_PATTERN =
            Pattern.compile("\\b([A-Z0-9][A-Z0-9 .\\-]{3,18}[A-Z0-9])\\b");
    // Birim: ADET, KG, LT vb.
    private static final Pattern UNIT_PATTERN =
            Pattern.compile("\\b(ADET|ADT|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\\b",
                    Pattern.CASE_INSENSITIVE);
    // KDV oranı: "%18", "18%", "% 18" gibi
    private static final Pattern VAT_PATTERN =
            Pattern.compile("(?:%\\s*(1|8|10|18|20)\\b|\\b(1|8|10|18|20)\\s*%)");

    // Faturada atlanan satır başlangıçları (Türkçe fatura başlıkları + dipnot)
    private static final List<String> SKIP_PREFIXES = List.of(
            "sıra", "sira", "satır", "satir", "birim", "toplam", "genel",
            "kdv", "vergi", "iban", "banka", "sayfa", "page", "tarih",
            "fatura", "irsaliye", "alıcı", "alici", "satıcı", "satici",
            "müşteri", "musteri", "tc kimlik", "adres", "telefon",
            "e-posta", "email", "web",
            // Ek dipnot / alt bilgi başlangıçları
            "not:", "açıklama:", "aciklama:", "düzenleme tarihi", "vade",
            "ödeme", "odeme", "kargo", "teslimat", "sipariş no", "siparis no",
            "imza", "kaşe", "kase", "yetkili"
    );

    // Tablo sonu (footer) satır başlangıçları — bu satır görülünce parse durdurulur
    private static final List<String> TABLE_FOOTER_PREFIXES = List.of(
            "toplam", "genel toplam", "ara toplam", "kdv toplam", "kdv matrah",
            "vergi toplam", "ödenecek", "odenecek", "net toplam",
            "subtotal", "total", "grand total",
            // e-Arşiv fatura özet satırları (regex yolunda da yakala)
            "mal hizmet toplam", "hesaplanan kdv", "vergiler dahil",
            "toplam i̇skonto", "toplam iskonto",
            // Satış notu dipnotları
            "güncel bakiye", "guncel bakiye",
            "teşekkür", "tesekkur",
            "yalnız", "yalniz",
            "fatura doğrulama", "fatura dogrulama",
            "mali i̇ade", "mali iade",
            "hesap bilgileri"
    );

    @Override
    public DocumentAnalyzeResponse analyze(MultipartFile file) throws IOException {
        String fileName = Optional.ofNullable(file.getOriginalFilename()).orElse("belge");
        String ext = fileName.toLowerCase();

        boolean scannedPdf = false;
        String parseMethod = "REGEX";
        List<DocumentItemResult> items;

        if (ext.endsWith(".pdf")) {
            ParseResult pr = parsePdf(file);
            items = pr.items();
            scannedPdf = pr.scannedPdf();
            parseMethod = pr.parseMethod();
        } else if (isImage(ext)) {
            String ocrText = callOcrService(file);
            items = parseText(ocrText, fileName);
            scannedPdf = true;
            parseMethod = "OCR";
        } else {
            throw new BusinessException(
                    "Desteklenmeyen dosya formatı. Lütfen PDF veya görüntü (JPG, PNG) yükleyin. Alınan: " + fileName);
        }

        // Duplicate ürün satırlarını birleştir (aynı barkod/isim → quantity topla)
        Map<String, DocumentItemResult> deduped = new LinkedHashMap<>();
        int nullKeySeq = 0;
        for (DocumentItemResult item : items) {
            String key = item.getExtractedCode() != null
                    ? item.getExtractedCode()
                    : item.getExtractedName() != null
                        ? item.getExtractedName().toLowerCase().trim()
                        : "NULL_" + nullKeySeq++;
            if (!key.startsWith("NULL_") && deduped.containsKey(key)) {
                DocumentItemResult ex = deduped.get(key);
                double merged =
                        (ex.getExtractedQuantity()   != null ? ex.getExtractedQuantity()   : 0.0)
                      + (item.getExtractedQuantity() != null ? item.getExtractedQuantity() : 0.0);
                ex.setExtractedQuantity(merged);
                List<String> flags = ex.getWarningFlags() != null
                        ? new ArrayList<>(ex.getWarningFlags()) : new ArrayList<>();
                flags.add("DUPLICATE_MERGED");
                ex.setWarningFlags(flags);
            } else {
                deduped.put(key, item);
            }
        }
        items = new ArrayList<>(deduped.values());

        long found = items.stream().filter(i -> "FOUND".equals(i.getMatchStatus())).count();

        return DocumentAnalyzeResponse.builder()
                .fileName(fileName)
                .totalItems(items.size())
                .foundItems((int) found)
                .notFoundItems(items.size() - (int) found)
                .items(items)
                .scannedPdf(scannedPdf)
                .parseMethod(parseMethod)
                .build();
    }

    private boolean isImage(String ext) {
        return ext.endsWith(".jpg") || ext.endsWith(".jpeg")
                || ext.endsWith(".png") || ext.endsWith(".webp")
                || ext.endsWith(".bmp");
    }

    // ── OCR SERVİSİ ÇAĞRISI ─────────────────────────────────────────────────

    private String callOcrService(MultipartFile file) throws IOException {
        RestTemplate rest = new RestTemplate();

        LinkedMultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        byte[] bytes = file.getBytes();
        body.add("file", new ByteArrayResource(bytes) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        });

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        try {
            ResponseEntity<Map> response = rest.exchange(
                    ocrServiceUrl + "/ocr/extract",
                    HttpMethod.POST,
                    new HttpEntity<>(body, headers),
                    Map.class
            );
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                String text = (String) response.getBody().get("text");
                return text != null ? text : "";
            }
        } catch (Exception e) {
            log.error("OCR servisi çağrılamadı: {}", e.getMessage());
            throw new BusinessException("OCR servisi yanıt vermedi: " + e.getMessage());
        }
        throw new BusinessException("OCR servisi boş yanıt döndürdü");
    }

    // ── PDF PARSE ────────────────────────────────────────────────────────────

    /** parsePdf() dönüş tipi: item listesi + parse yöntemi metadata */
    private record ParseResult(List<DocumentItemResult> items,
                                boolean scannedPdf,
                                String parseMethod) {}

    private ParseResult parsePdf(MultipartFile file) throws IOException {
        byte[] bytes = file.getBytes();
        try (PDDocument doc = Loader.loadPDF(bytes)) {

            // ── 1. Taranmış PDF tespiti → OCR fallback ───────────────────────
            PDFTextStripper quickCheck = new PDFTextStripper();
            quickCheck.setEndPage(1);
            String firstPageText = quickCheck.getText(doc);
            if (firstPageText == null || firstPageText.trim().length() < 50) {
                log.warn("parsePdf: Taranmış PDF tespit edildi — Python OCR'a yönlendiriliyor");
                String ocrText = callOcrService(file);
                List<DocumentItemResult> ocrItems = parseText(ocrText, file.getOriginalFilename());
                return new ParseResult(ocrItems, true, "OCR");
            }

            // ── 2. Pozisyonel tablo çıkarımı ─────────────────────────────────
            Optional<PositionalTableExtractor.ExtractionResult> tableOpt =
                    PositionalTableExtractor.extract(doc);

            if (tableOpt.isPresent()) {
                PositionalTableExtractor.ExtractionResult extraction = tableOpt.get();
                log.info("parsePdf: Pozisyonel mod — {} veri satırı", extraction.dataRows().size());

                TableRowParser rowParser = new TableRowParser(extraction.headerRow());
                List<ParsedLine> parsedLines = new ArrayList<>();
                MultiLineAggregator aggregator = new MultiLineAggregator();

                for (TableRow tableRow : extraction.dataRows()) {
                    ParsedLine parsed = rowParser.parse(tableRow);
                    if (parsed.name == null || parsed.name.isBlank()) continue;
                    List<ParsedLine> ready = aggregator.process(parsed);
                    parsedLines.addAll(ready);
                }
                parsedLines.addAll(aggregator.flush());

                if (!parsedLines.isEmpty()) {
                    List<DocumentItemResult> results = buildResults(parsedLines);
                    log.info("parsePdf [{}]: Pozisyonel mod → {} ürün", file.getOriginalFilename(), results.size());
                    return new ParseResult(results, false, "POSITIONAL");
                }
                log.warn("parsePdf: Pozisyonel mod 0 ürün — regex yoluna düşülüyor");
            }

            // ── 3. Regex fallback ─────────────────────────────────────────────
            log.info("parsePdf: Regex parse yoluna geçildi");
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setSortByPosition(true);
            String fullText = stripper.getText(doc);
            List<DocumentItemResult> items = parseText(fullText, file.getOriginalFilename());
            return new ParseResult(items, false, "REGEX");
        }
    }

    /** ParsedLine listesini VariantGrouper → matchToProduct() → DocumentItemResult listesine dönüştürür. */
    private List<DocumentItemResult> buildResults(List<ParsedLine> parsedLines) {
        List<VariantGrouper.VariantGroup> groups = VariantGrouper.group(parsedLines);
        List<DocumentItemResult> results = new ArrayList<>();
        int rowIndex = 0;

        for (VariantGrouper.VariantGroup group : groups) {
            if (group.isGroup()) {
                // Durum 2: varyant grubu
                List<com.sedcore.product.model.DocumentVariantItem> variantItems =
                        group.variants().stream().map(vl -> com.sedcore.product.model.DocumentVariantItem.builder()
                                .attributeValue(vl.attributeValue())
                                .attributeType(vl.attributeType())
                                .quantity(vl.line().quantity)
                                .unitPrice(vl.line().unitPrice)
                                .barcode(vl.line().code != null && "BARCODE".equals(vl.line().codeType)
                                        ? vl.line().code : null)
                                .rawText(vl.line().name)
                                .build()
                        ).toList();

                DocumentItemResult result = matchToProduct(group.base(), ++rowIndex,
                        group.base().name, variantItems);
                results.add(result);
            } else {
                // Durum 1: tekil ürün
                results.add(matchToProduct(group.base(), ++rowIndex,
                        group.base().name, Collections.emptyList()));
            }
        }
        return results;
    }

    // ── METİN PARSE (PDF + OCR ortak) ────────────────────────────────────────

    private List<DocumentItemResult> parseText(String text, String fileName) {
        List<DocumentItemResult> results = new ArrayList<>();

        String[] lines = text.split("\\r?\\n");

        // 1. Başlık satırını tara (ilk 20 satır içinde)
        ColumnPositionMapper columnMapper = null;
        ColumnAwareLineParser columnParser = null;
        int headerLineIndex = -1;

        // Başlık satırı tüm satırlarda aranır — e-Arşiv gibi uzun başlıklı belgeler için limit kaldırıldı.
        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();
            if (InvoiceHeaderDetector.isHeader(line)) {
                Set<ColumnType> matchedColumns = InvoiceHeaderDetector.detect(line);
                columnMapper = new ColumnPositionMapper(line, matchedColumns);
                columnParser = new ColumnAwareLineParser(columnMapper);
                headerLineIndex = i;
                log.info("DocumentAnalyze: Başlık satırı tespit edildi (satır {}): '{}'", i, line);
                break;
            }
        }

        // 2. Satırları parse et → ParsedLine listesi topla
        MultiLineAggregator aggregator = new MultiLineAggregator();
        List<ParsedLine> parsedLines = new ArrayList<>();

        for (int i = 0; i < lines.length; i++) {
            String rawLine = lines[i];
            String line = rawLine.trim();

            // Başlık satırını ve öncesini atla
            if (headerLineIndex >= 0 && i <= headerLineIndex) continue;
            if (line.isBlank() || line.length() < 4) continue;

            // Tablo sonu (footer) tespiti
            if (headerLineIndex >= 0 && isTableFooterLine(line)) {
                log.debug("parseText: Tablo sonu (satır {}): '{}'", i, line);
                break;
            }

            if (shouldSkipLine(line)) continue;

            ParsedLine parsed;
            if (columnParser != null && !columnMapper.isEmpty()) {
                parsed = columnParser.parse(rawLine);
            } else {
                parsed = extractLineInfo(line);
            }

            if (parsed.name == null || parsed.name.isBlank()) continue;

            List<ParsedLine> ready = aggregator.process(parsed);
            parsedLines.addAll(ready);
        }

        // Kalan pending satırları ekle
        parsedLines.addAll(aggregator.flush());

        // 3. VariantGrouper → matchToProduct → DocumentItemResult
        List<DocumentItemResult> results = buildResults(parsedLines);

        log.info("DocumentAnalyze [{}]: {} ürün kalemi ({}  eşleşme)",
                fileName, results.size(),
                results.stream().filter(r -> "FOUND".equals(r.getMatchStatus())).count());
        return results;
    }

    // ── SATIR PARSE (Regex Fallback) ─────────────────────────────────────────

    private boolean shouldSkipLine(String line) {
        String lower = line.toLowerCase().trim();
        if (lower.length() < 5) return true;
        for (String prefix : SKIP_PREFIXES) {
            if (lower.startsWith(prefix)) return true;
        }
        // Sadece rakam/özel karakter içeren satırlar
        if (lower.replaceAll("[^a-zğüşıöça-z]", "").isBlank()) return true;
        return false;
    }

    private boolean isTableFooterLine(String line) {
        String lower = line.toLowerCase().trim();
        for (String prefix : TABLE_FOOTER_PREFIXES) {
            if (lower.startsWith(prefix)) return true;
        }
        return false;
    }

    private ParsedLine extractLineInfo(String line) {
        ParsedLine result = new ParsedLine();

        // 1. EAN13 barkod ara
        Matcher barcodeMatcher = BARCODE_PATTERN.matcher(line);
        if (barcodeMatcher.find()) {
            result.code = barcodeMatcher.group(1);
            result.codeType = "BARCODE";
        }

        // 2. OEM kodu ara (barkod bulunamadıysa)
        if (result.code == null) {
            String upper = line.toUpperCase();
            Matcher oemMatcher = OEM_PATTERN.matcher(upper);
            while (oemMatcher.find()) {
                String candidate = oemMatcher.group(1).trim();
                boolean hasLetter = candidate.matches(".*[A-Z].*");
                boolean hasDigit = candidate.matches(".*[0-9].*");
                if (hasLetter && hasDigit && candidate.length() >= 4) {
                    result.code = candidate;
                    result.codeType = "OEM";
                    break;
                }
            }
        }

        // 3. Birim çıkar
        Matcher unitMatcher = UNIT_PATTERN.matcher(line);
        if (unitMatcher.find()) {
            result.unit = unitMatcher.group(1).toUpperCase();
        }

        // 4. KDV oranı çıkar
        Matcher vatMatcher = VAT_PATTERN.matcher(line);
        if (vatMatcher.find()) {
            String vatGroup = vatMatcher.group(1) != null ? vatMatcher.group(1) : vatMatcher.group(2);
            try {
                result.vatRate = Double.parseDouble(vatGroup);
            } catch (NumberFormatException ignored) {}
        }

        // 5. Sayıları çıkar (miktar ve fiyat)
        List<Double> numbers = extractNumbers(line);
        if (!numbers.isEmpty()) {
            for (Double n : numbers) {
                if (n == Math.floor(n) && n >= 1 && n <= 9999 && result.quantity == null) {
                    result.quantity = n;
                }
            }
            List<Double> prices = numbers.stream()
                    .filter(n -> n > 0 && !n.equals(result.quantity))
                    .sorted()
                    .collect(Collectors.toList());
            if (!prices.isEmpty()) {
                result.unitPrice = prices.get(0);
            }
            // Satır toplamı: en az 2 farklı sayı varsa en büyüğü toplam fiyattır
            if (prices.size() >= 2) {
                result.totalPrice = prices.get(prices.size() - 1);
            }
        }

        // 6. Ürün adını çıkar — kodu, sayıları ve birimi temizle
        String nameStr = line;
        if (result.code != null) nameStr = nameStr.replace(result.code, " ");
        nameStr = nameStr.replaceAll("\\b\\d+[.,]?\\d*\\b", " ");
        nameStr = nameStr.replaceAll("(?i)\\b(ADT|ADET|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\\b", " ");
        nameStr = nameStr.replaceAll("[%₺$€@#*]", " ");
        nameStr = nameStr.replaceAll("\\s+", " ").trim();
        nameStr = nameStr.replaceAll("^\\d{1,3}\\s+", "").trim();

        if (nameStr.length() >= 3 && nameStr.matches(".*[a-zA-ZğüşıöçĞÜŞİÖÇ].*")) {
            result.name = nameStr.substring(0, Math.min(nameStr.length(), 200));
        }

        return result;
    }

    private List<Double> extractNumbers(String line) {
        List<Double> numbers = new ArrayList<>();
        String normalized = line.replaceAll("(\\d)\\.(\\d{3})", "$1$2");
        normalized = normalized.replace(",", ".");
        Matcher m = Pattern.compile("\\b(\\d{1,8}(?:\\.\\d{1,4})?)\\b").matcher(normalized);
        while (m.find()) {
            try {
                double val = Double.parseDouble(m.group(1));
                if (val > 0) numbers.add(val);
            } catch (NumberFormatException ignored) {}
        }
        return numbers;
    }

    // ── ÜRÜN EŞLEŞTİRME ─────────────────────────────────────────────────────

    private DocumentItemResult matchToProduct(ParsedLine parsed, int rowIndex, String rawText,
                                               List<com.sedcore.product.model.DocumentVariantItem> variants) {
        boolean isGroup = variants != null && !variants.isEmpty();
        DocumentItemResult.DocumentItemResultBuilder builder = DocumentItemResult.builder()
                .rowIndex(rowIndex)
                .rawText(rawText)
                .extractedName(parsed.name)
                .extractedCode(parsed.code)
                .extractedQuantity(parsed.quantity)
                .extractedUnitPrice(parsed.unitPrice)
                .unit(parsed.unit)
                .vatRate(parsed.vatRate)
                .vatIncluded(parsed.vatIncluded)
                .totalPrice(parsed.totalPrice)
                .variantGroup(isGroup)
                .variants(isGroup ? variants : Collections.emptyList());

        // 1. EAN13 barkod ile eşleştir
        if ("BARCODE".equals(parsed.codeType) && parsed.code != null) {
            var barcodeOpt = barcodeRepository.findByBarcodeCode(parsed.code);
            if (barcodeOpt.isPresent() && barcodeOpt.get().getVariant() != null) {
                return enrichFromVariant(builder, barcodeOpt.get().getVariant(), "BARCODE",
                        buildWarningFlags(parsed, "BARCODE"));
            }
        }

        // 2. OEM numarası ile eşleştir
        if (parsed.code != null && !"BARCODE".equals(parsed.codeType)) {
            var oemList = oemNumberRepository.findByOemNumberIgnoreCase(parsed.code);
            if (!oemList.isEmpty() && oemList.get(0).getVariant() != null) {
                return enrichFromVariant(builder, oemList.get(0).getVariant(), "OEM",
                        buildWarningFlags(parsed, "OEM"));
            }
        }

        // 3. İsim ile ara
        if (parsed.name != null && parsed.name.length() >= 3) {
            String keyword = extractKeywords(parsed.name);
            var products = productRepository.searchProducts(keyword);
            if (!products.isEmpty()) {
                var product = products.get(0);
                var productVariants = productVariantRepository
                        .findByProductIdAndIsDeleted(product.getId(), false);
                if (!productVariants.isEmpty()) {
                    var variant = productVariants.get(0);
                    return builder
                            .matchStatus("FOUND")
                            .matchType("NAME")
                            .matchedProductId(product.getId())
                            .matchedProductName(product.getName())
                            .matchedVariantId(variant.getId())
                            .matchedSku(variant.getSku())
                            .matchConfidence(0.5)
                            .warningFlags(buildWarningFlags(parsed, "NAME"))
                            .build();
                }
            }
        }

        // 4. Bulunamadı
        return builder
                .matchStatus("NOT_FOUND")
                .matchConfidence(0.0)
                .warningFlags(buildWarningFlags(parsed, null))
                .build();
    }

    private DocumentItemResult enrichFromVariant(
            DocumentItemResult.DocumentItemResultBuilder builder,
            com.sedcore.product.entity.ProductVariant variant,
            String matchType,
            List<String> warningFlags) {

        String productName = variant.getName();
        String productId = null;

        if (variant.getProduct() != null) {
            productId = variant.getProduct().getId();
            if (variant.getProduct().getName() != null) {
                productName = variant.getProduct().getName();
            }
        }

        double confidence = "BARCODE".equals(matchType) ? 1.0
                          : "OEM".equals(matchType)     ? 0.9 : 0.5;
        return builder
                .matchStatus("FOUND")
                .matchType(matchType)
                .matchedProductId(productId)
                .matchedProductName(productName)
                .matchedVariantId(variant.getId())
                .matchedSku(variant.getSku())
                .matchedCurrentStock(0.0)
                .matchConfidence(confidence)
                .warningFlags(warningFlags)
                .build();
    }

    private List<String> buildWarningFlags(ParsedLine parsed, String matchType) {
        List<String> flags = new ArrayList<>();
        if ("NAME".equals(matchType)) {
            flags.add("NAME_MATCH_UNCERTAIN");
        }
        if (parsed.unitPrice == null) {
            flags.add("NO_PRICE");
        }
        if (parsed.totalPrice != null && parsed.unitPrice != null && parsed.quantity != null) {
            double expected = parsed.unitPrice * parsed.quantity;
            if (expected > 0 && Math.abs(parsed.totalPrice - expected) / expected > 0.05) {
                flags.add("PRICE_MISMATCH");
            }
        }
        return flags;
    }

    private String extractKeywords(String name) {
        String[] words = name.trim().split("\\s+");
        int limit = Math.min(words.length, 3);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < limit; i++) {
            if (words[i].length() >= 3) {
                if (sb.length() > 0) sb.append(" ");
                sb.append(words[i]);
            }
        }
        return sb.length() >= 3 ? sb.toString() : name;
    }
}
