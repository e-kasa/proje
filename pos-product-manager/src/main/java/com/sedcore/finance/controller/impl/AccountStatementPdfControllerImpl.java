package com.sedcore.finance.controller.impl;

import com.sedcore.common.notification.EmailService;
import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.supplier.repository.SupplierRepository;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Account Statement PDF export endpoint (Sprint 5, P2.3 — 2026-04-24).
 *
 * <p>Minimum viable PDFBox implementation — basit tablo + opening/closing totals.
 * Daha zengin format (logo, firma bilgisi, multi-page header) gelecek iterasyon.</p>
 *
 * <p>Email endpoint (POST /email) ayrı mini-sprint'e bırakıldı — spring-boot-starter-mail
 * + SMTP config + secret yönetimi için risk azaltma.</p>
 *
 * <p>Client-side PDF (Flutter `statement_pdf_service.dart`) bu endpoint hazır olunca
 * deprecate edilebilir; ama iki yolu paralel tutmak acceptable (offline senaryolar).</p>
 */
@RestController
@RequestMapping("api/v1/account-statements")
@RequiredArgsConstructor
@Slf4j
public class AccountStatementPdfControllerImpl {

    private final AccountTransactionRepository accountTransactionRepository;
    private final CustomerRepository customerRepository;
    private final SupplierRepository supplierRepository;
    private final EmailService emailService;

    private static final DateTimeFormatter DATE_FMT =
            DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final DateTimeFormatter DATETIME_FMT =
            DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");

    @Transactional(readOnly = true)
    @GetMapping(value = "/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> getStatementPdf(
            @RequestParam String accountType,
            @RequestParam String accountId,
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDateParam,
            @RequestParam("endDate")   @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDateParam) {
        try {
            StatementPdf pdf = buildStatementPdf(accountType, accountId, startDateParam, endDateParam);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", pdf.filename);
            headers.setContentLength(pdf.bytes.length);
            return ResponseEntity.ok().headers(headers).body(pdf.bytes);
        } catch (Exception e) {
            log.error("Statement PDF hatasi: type={}, id={}", accountType, accountId, e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Email endpoint (Sprint 5 mini, 2026-04-24).
     *
     * POST /product/api/v1/account-statements/email
     *   ?accountType=&accountId=&startDate=&endDate=&to=<email>[&subject=...]
     *
     * Response:
     *   { sent: true, to, subject }  veya
     *   { sent: false, reason: "mail.enabled=false" }
     *
     * Mail service devre dışıysa (mail.enabled=false veya SMTP config yok) 200 döner
     * ama sent=false — client UX'i "email gönderilemedi, PDF indir" yönlendirir.
     */
    @Transactional(readOnly = true)
    @PostMapping("/email")
    public ResponseEntity<ApiResponse<Map<String, Object>>> emailStatement(
            @RequestParam String accountType,
            @RequestParam String accountId,
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDateParam,
            @RequestParam("endDate")   @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDateParam,
            @RequestParam String to,
            @RequestParam(required = false) String subject) {
        try {
            StatementPdf pdf = buildStatementPdf(accountType, accountId, startDateParam, endDateParam);

            String effectiveSubject = subject != null && !subject.isBlank()
                    ? subject
                    : String.format("Hesap Ekstresi - %s (%s - %s)",
                            pdf.accountName,
                            startDateParam.format(DATE_FMT),
                            endDateParam.format(DATE_FMT));

            String body = String.format(
                    "Sayin %s,%n%n%s - %s tarih araligi ekstresini ekte iletiyoruz.%n%nSEDCORE POS",
                    pdf.accountName,
                    startDateParam.format(DATE_FMT),
                    endDateParam.format(DATE_FMT));

            boolean sent = emailService.sendWithAttachment(
                    to, effectiveSubject, body, pdf.filename, pdf.bytes);

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("sent", sent);
            result.put("to", to);
            result.put("subject", effectiveSubject);
            result.put("attachmentSize", pdf.bytes.length);
            if (!sent) {
                result.put("reason", emailService.isEnabled()
                        ? "send_failed" : "mail_disabled");
            }
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (Exception e) {
            log.error("Statement email hatasi: type={}, id={}, to={}",
                    accountType, accountId, to, e);
            throw ExceptionMapper.map(e);
        }
    }

    /** PDF oluşturma ortak path — hem /pdf hem /email kullanır. */
    private StatementPdf buildStatementPdf(String accountType, String accountId,
                                           LocalDate startDateParam, LocalDate endDateParam) throws Exception {
        LocalDateTime startDate = startDateParam.atStartOfDay();
        LocalDateTime endDate = endDateParam.atTime(LocalTime.MAX);
        boolean isCustomer = "CUSTOMER".equalsIgnoreCase(accountType);

        String accountName = isCustomer
                ? customerRepository.findById(accountId).map(c -> c.getName()).orElse(accountId)
                : supplierRepository.findById(accountId).map(s -> s.getName()).orElse(accountId);

        List<AccountTransaction> txs = isCustomer
                ? accountTransactionRepository.findCustomerStatement(accountId, startDate, endDate)
                : accountTransactionRepository.findSupplierStatement(accountId, startDate, endDate);

        BigDecimal openingBalance = isCustomer
                ? accountTransactionRepository.customerOpeningBalance(accountId, startDate)
                : accountTransactionRepository.supplierOpeningBalance(accountId, startDate);
        if (openingBalance == null) openingBalance = BigDecimal.ZERO;

        byte[] bytes = renderPdf(accountType, accountName,
                startDateParam, endDateParam, openingBalance, txs);

        String filename = String.format("statement-%s-%s-%s.pdf",
                accountType.toLowerCase(),
                accountId,
                LocalDate.now().format(DATE_FMT).replace('.', '-'));

        return new StatementPdf(bytes, filename, accountName);
    }

    private record StatementPdf(byte[] bytes, String filename, String accountName) {}

    /**
     * PDFBox ile minimum viable statement render.
     *
     * Format:
     *   Başlık + hesap adı + tarih aralığı
     *   Opening balance
     *   Tablo: Tarih | Açıklama | Borç | Alacak | Running
     *   Closing balance + toplam borç + toplam alacak
     */
    private byte[] renderPdf(String accountType, String accountName,
                             LocalDate startDate, LocalDate endDate,
                             BigDecimal openingBalance,
                             List<AccountTransaction> txs) throws Exception {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            var fontRegular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            var fontBold    = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);

            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            PDPageContentStream cs = new PDPageContentStream(doc, page);

            float margin = 40f;
            float y = PDRectangle.A4.getHeight() - margin;

            // Header
            cs.beginText();
            cs.setFont(fontBold, 16f);
            cs.newLineAtOffset(margin, y);
            cs.showText("Hesap Ekstresi");
            cs.endText();
            y -= 24f;

            cs.beginText();
            cs.setFont(fontRegular, 11f);
            cs.newLineAtOffset(margin, y);
            cs.showText(String.format("%s: %s",
                    "CUSTOMER".equalsIgnoreCase(accountType) ? "Musteri" : "Tedarikci",
                    sanitize(accountName)));
            cs.endText();
            y -= 16f;

            cs.beginText();
            cs.setFont(fontRegular, 10f);
            cs.newLineAtOffset(margin, y);
            cs.showText(String.format("Tarih araligi: %s - %s",
                    startDate.format(DATE_FMT), endDate.format(DATE_FMT)));
            cs.endText();
            y -= 20f;

            cs.beginText();
            cs.setFont(fontBold, 11f);
            cs.newLineAtOffset(margin, y);
            cs.showText(String.format("Acilis bakiye: %s TL", formatMoney(openingBalance)));
            cs.endText();
            y -= 20f;

            // Table header
            float colDate = margin;
            float colDesc = margin + 90f;
            float colDebit = margin + 330f;
            float colCredit = margin + 400f;
            float colRunning = margin + 470f;

            cs.beginText();
            cs.setFont(fontBold, 9f);
            cs.newLineAtOffset(colDate, y);
            cs.showText("Tarih");
            cs.endText();
            cs.beginText(); cs.setFont(fontBold, 9f); cs.newLineAtOffset(colDesc, y); cs.showText("Aciklama"); cs.endText();
            cs.beginText(); cs.setFont(fontBold, 9f); cs.newLineAtOffset(colDebit, y); cs.showText("Borc"); cs.endText();
            cs.beginText(); cs.setFont(fontBold, 9f); cs.newLineAtOffset(colCredit, y); cs.showText("Alacak"); cs.endText();
            cs.beginText(); cs.setFont(fontBold, 9f); cs.newLineAtOffset(colRunning, y); cs.showText("Bakiye"); cs.endText();
            y -= 14f;

            // Rows
            BigDecimal running = openingBalance;
            BigDecimal totalDebit = BigDecimal.ZERO;
            BigDecimal totalCredit = BigDecimal.ZERO;

            for (AccountTransaction t : txs) {
                if (y < margin + 40f) {
                    // Yeni sayfa
                    cs.close();
                    page = new PDPage(PDRectangle.A4);
                    doc.addPage(page);
                    cs = new PDPageContentStream(doc, page);
                    y = PDRectangle.A4.getHeight() - margin;
                }

                running = running.add(t.getDebitAmount()).subtract(t.getCreditAmount());
                totalDebit = totalDebit.add(t.getDebitAmount());
                totalCredit = totalCredit.add(t.getCreditAmount());

                String dateStr = t.getTransactionDate() != null
                        ? t.getTransactionDate().format(DATETIME_FMT) : "-";
                String desc = sanitize(truncate(
                        t.getDescription() != null ? t.getDescription() : "", 40));

                cs.beginText(); cs.setFont(fontRegular, 8f); cs.newLineAtOffset(colDate, y); cs.showText(dateStr); cs.endText();
                cs.beginText(); cs.setFont(fontRegular, 8f); cs.newLineAtOffset(colDesc, y); cs.showText(desc); cs.endText();
                cs.beginText(); cs.setFont(fontRegular, 8f); cs.newLineAtOffset(colDebit, y); cs.showText(formatMoney(t.getDebitAmount())); cs.endText();
                cs.beginText(); cs.setFont(fontRegular, 8f); cs.newLineAtOffset(colCredit, y); cs.showText(formatMoney(t.getCreditAmount())); cs.endText();
                cs.beginText(); cs.setFont(fontRegular, 8f); cs.newLineAtOffset(colRunning, y); cs.showText(formatMoney(running)); cs.endText();
                y -= 12f;
            }

            // Footer totals
            y -= 10f;
            cs.beginText();
            cs.setFont(fontBold, 10f);
            cs.newLineAtOffset(margin, y);
            cs.showText(String.format("Toplam borc: %s TL | Toplam alacak: %s TL | Kapanis: %s TL",
                    formatMoney(totalDebit), formatMoney(totalCredit), formatMoney(running)));
            cs.endText();

            cs.close();
            doc.save(out);
            return out.toByteArray();
        }
    }

    private static String formatMoney(BigDecimal v) {
        if (v == null) return "0.00";
        return v.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString();
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max - 1) + "…";
    }

    /**
     * Standard14 fontlar (Helvetica) WinAnsi encoding — Türkçe özel karakterler (ğşıç...)
     * renderlenirken "Could not encode" throw eder. Geçici çözüm: ASCII'ye downgrade.
     * Gelecek iterasyonda TrueType Türkçe font embed edilir (NotoSans/Roboto).
     */
    private static String sanitize(String s) {
        if (s == null) return "";
        return s.replace('ı', 'i').replace('İ', 'I')
                .replace('ş', 's').replace('Ş', 'S')
                .replace('ğ', 'g').replace('Ğ', 'G')
                .replace('ü', 'u').replace('Ü', 'U')
                .replace('ö', 'o').replace('Ö', 'O')
                .replace('ç', 'c').replace('Ç', 'C');
    }
}
