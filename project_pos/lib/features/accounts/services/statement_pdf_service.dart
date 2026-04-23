import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:project_pos/core/utils/formatters.dart';

/// Cari hesap ekstresi PDF üretici/önizleyici.
///
/// Tek girişi var: [show] — `Printing.layoutPdf` ile native print/share/save
/// dialogunu açar.
class StatementPdfService {
  static final _dateFmt = DateFormat('dd.MM.yyyy');

  static Future<void> show({
    required String accountName,
    required String accountType, // 'CUSTOMER' | 'SUPPLIER'
    required DateTime startDate,
    required DateTime endDate,
    required double openingBalance,
    required double closingBalance,
    required double totalDebit,
    required double totalCredit,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final fonts = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
    ]);
    final font = fonts[0];
    final fontBold = fonts[1];

    await Printing.layoutPdf(
      name: 'ekstre_${accountName.replaceAll(' ', '_')}',
      onLayout: (PdfPageFormat format) async {
        final doc = pw.Document(theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ));

        doc.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(24),
            header: (ctx) => _header(accountName, accountType, startDate, endDate),
            footer: (ctx) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ),
            build: (ctx) => [
              _summaryBox(openingBalance, totalDebit, totalCredit, closingBalance),
              pw.SizedBox(height: 12),
              _transactionTable(transactions),
            ],
          ),
        );

        return doc.save();
      },
    );
  }

  static pw.Widget _header(
    String accountName,
    String accountType,
    DateTime start,
    DateTime end,
  ) {
    final typeLabel = accountType == 'CUSTOMER' ? 'MÜŞTERİ' : 'TEDARİKÇİ';
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CARİ HESAP EKSTRESİ',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$typeLabel: $accountName',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text(
                '${_dateFmt.format(start)} — ${_dateFmt.format(end)}',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(
      double opening, double debit, double credit, double closing) {
    pw.Widget cell(String label, double value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text(appCurrencyFmt.format(value),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        cell('Açılış Bakiyesi', opening, PdfColors.blue700),
        pw.SizedBox(width: 6),
        cell('Toplam Borç', debit, PdfColors.red700),
        pw.SizedBox(width: 6),
        cell('Toplam Alacak', credit, PdfColors.green700),
        pw.SizedBox(width: 6),
        cell('Kapanış Bakiyesi', closing, PdfColors.black),
      ],
    );
  }

  static pw.Widget _transactionTable(List<Map<String, dynamic>> transactions) {
    return pw.TableHelper.fromTextArray(
      headers: ['Tarih', 'Açıklama', 'Borç', 'Alacak', 'Bakiye'],
      data: transactions.map((tx) {
        final iso = shortDateString(tx['transactionDate']?.toString());
        // YYYY-MM-DD → DD.MM.YYYY
        final date = iso.length == 10 ? iso.split('-').reversed.join('.') : iso;
        final desc = tx['description']?.toString() ?? '-';
        final debit = (tx['debitAmount'] ?? 0).toDouble();
        final credit = (tx['creditAmount'] ?? 0).toDouble();
        final balance = (tx['runningBalance'] ?? 0).toDouble();
        return [
          date,
          desc,
          debit > 0 ? appCurrencyFmt.format(debit) : '-',
          credit > 0 ? appCurrencyFmt.format(credit) : '-',
          appCurrencyFmt.format(balance),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.4),
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }
}
