const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, TabStopType, TabStopPosition
} = require("docx");

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const accentBorder = { style: BorderStyle.SINGLE, size: 1, color: "2E75B6" };
const accentBorders = { top: accentBorder, bottom: accentBorder, left: accentBorder, right: accentBorder };

const cellMargins = { top: 80, bottom: 80, left: 120, right: 120 };

function headerCell(text, width) {
  return new TableCell({
    borders: accentBorders,
    width: { size: width, type: WidthType.DXA },
    shading: { fill: "2E75B6", type: ShadingType.CLEAR },
    margins: cellMargins,
    verticalAlign: "center",
    children: [new Paragraph({ children: [new TextRun({ text, bold: true, color: "FFFFFF", font: "Arial", size: 20 })] })]
  });
}

function cell(text, width, opts = {}) {
  const runs = Array.isArray(text)
    ? text
    : [new TextRun({ text, font: "Arial", size: 20, ...(opts.bold ? { bold: true } : {}), ...(opts.color ? { color: opts.color } : {}) })];
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    shading: opts.fill ? { fill: opts.fill, type: ShadingType.CLEAR } : undefined,
    margins: cellMargins,
    children: [new Paragraph({ children: runs })]
  });
}

function codeBlock(lines) {
  return lines.map(line => new Paragraph({
    spacing: { before: 20, after: 20 },
    indent: { left: 360 },
    children: [new TextRun({ text: line, font: "Consolas", size: 18, color: "1A1A1A" })]
  }));
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.afterSpacing ?? 120, before: opts.beforeSpacing ?? 0 },
    alignment: opts.align,
    children: Array.isArray(text) ? text : [new TextRun({ text, font: "Arial", size: 22, ...opts })]
  });
}

function heading(text, level = HeadingLevel.HEADING_1) {
  return new Paragraph({ heading: level, spacing: { before: 360, after: 180 }, children: [new TextRun({ text, font: "Arial" })] });
}

function h2(text) { return heading(text, HeadingLevel.HEADING_2); }
function h3(text) { return heading(text, HeadingLevel.HEADING_3); }

function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { after: 60 },
    children: Array.isArray(text) ? text : [new TextRun({ text, font: "Arial", size: 22 })]
  });
}

function numberedItem(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "numbers", level },
    spacing: { after: 60 },
    children: Array.isArray(text) ? text : [new TextRun({ text, font: "Arial", size: 22 })]
  });
}

function warningBox(title, text) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 1, color: "E67E22" }, bottom: { style: BorderStyle.SINGLE, size: 1, color: "E67E22" }, left: { style: BorderStyle.SINGLE, size: 6, color: "E67E22" }, right: { style: BorderStyle.SINGLE, size: 1, color: "E67E22" } },
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: "FFF3E0", type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        children: [
          new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: "\u26A0 " + title, bold: true, font: "Arial", size: 22, color: "E67E22" })] }),
          new Paragraph({ children: [new TextRun({ text, font: "Arial", size: 20 })] })
        ]
      })
    ]})]
  });
}

function infoBox(title, text) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 1, color: "2E75B6" }, bottom: { style: BorderStyle.SINGLE, size: 1, color: "2E75B6" }, left: { style: BorderStyle.SINGLE, size: 6, color: "2E75B6" }, right: { style: BorderStyle.SINGLE, size: 1, color: "2E75B6" } },
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: "E3F2FD", type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        children: [
          new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: "\u2139 " + title, bold: true, font: "Arial", size: 22, color: "2E75B6" })] }),
          new Paragraph({ children: [new TextRun({ text, font: "Arial", size: 20 })] })
        ]
      })
    ]})]
  });
}

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: "1A1A2E" },
        paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: "2E75B6" },
        paragraph: { spacing: { before: 240, after: 180 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: "333333" },
        paragraph: { spacing: { before: 180, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [
        { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "\u25E6", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
      ]},
      { reference: "numbers", levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.LOWER_LETTER, text: "%2)", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
      ]},
      { reference: "phases", levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "Faz %1:", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 720 } } } },
      ]},
    ]
  },
  sections: [
    // ── KAPAK SAYFASI ──
    {
      properties: {
        page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } }
      },
      children: [
        new Paragraph({ spacing: { before: 3600 } }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [new TextRun({ text: "TASARIM DOKUMANI", font: "Arial", size: 22, color: "2E75B6", bold: true })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 240 },
          children: [new TextRun({ text: "Sekt\u00F6re G\u00F6re \u00DCr\u00FCn Ayr\u0131nt\u0131lar\u0131", font: "Arial", size: 48, bold: true, color: "1A1A2E" })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 60 },
          children: [new TextRun({ text: "Mimari Tasar\u0131m Plan\u0131 ve Uygulama Rehberi", font: "Arial", size: 24, color: "666666" })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 600 },
          border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: "2E75B6", space: 12 } },
          children: [new TextRun({ text: "Project POS \u2014 Flutter Uygulamas\u0131", font: "Arial", size: 22, color: "999999" })]
        }),
        new Paragraph({ spacing: { before: 1200 } }),
        new Table({
          width: { size: 5000, type: WidthType.DXA },
          columnWidths: [2000, 3000],
          rows: [
            new TableRow({ children: [
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 2000, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "F5F5F5", type: ShadingType.CLEAR }, children: [new Paragraph({ children: [new TextRun({ text: "Tarih", bold: true, font: "Arial", size: 20 })] })] }),
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 3000, type: WidthType.DXA }, margins: cellMargins, children: [new Paragraph({ children: [new TextRun({ text: "7 Nisan 2026", font: "Arial", size: 20 })] })] }),
            ]}),
            new TableRow({ children: [
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 2000, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "F5F5F5", type: ShadingType.CLEAR }, children: [new Paragraph({ children: [new TextRun({ text: "Versiyon", bold: true, font: "Arial", size: 20 })] })] }),
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 3000, type: WidthType.DXA }, margins: cellMargins, children: [new Paragraph({ children: [new TextRun({ text: "1.0", font: "Arial", size: 20 })] })] }),
            ]}),
            new TableRow({ children: [
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 2000, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "F5F5F5", type: ShadingType.CLEAR }, children: [new Paragraph({ children: [new TextRun({ text: "Durum", bold: true, font: "Arial", size: 20 })] })] }),
              new TableCell({ borders: { top: border, bottom: border, left: border, right: border }, width: { size: 3000, type: WidthType.DXA }, margins: cellMargins, children: [new Paragraph({ children: [new TextRun({ text: "Taslak \u2014 Onay Bekliyor", font: "Arial", size: 20, color: "E67E22" })] })] }),
            ]}),
          ]
        }),
      ]
    },

    // ── ANA ICERIK ──
    {
      properties: {
        page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } }
      },
      headers: {
        default: new Header({
          children: [new Paragraph({
            border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC", space: 4 } },
            children: [
              new TextRun({ text: "Sekt\u00F6re G\u00F6re \u00DCr\u00FCn Ayr\u0131nt\u0131lar\u0131 \u2014 Mimari Tasar\u0131m Plan\u0131", font: "Arial", size: 16, color: "999999" }),
            ]
          })]
        })
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            border: { top: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC", space: 4 } },
            tabStops: [{ type: TabStopType.RIGHT, position: TabStopPosition.MAX }],
            children: [
              new TextRun({ text: "Project POS", font: "Arial", size: 16, color: "999999" }),
              new TextRun({ text: "\tSayfa ", font: "Arial", size: 16, color: "999999" }),
              new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16, color: "999999" }),
            ]
          })]
        })
      },
      children: [
        // ═══════════ 1. MEVCUT DURUM ANALİZİ ═══════════
        heading("1. Mevcut Durum Analizi"),

        p("Projede hali haz\u0131rda g\u00FC\u00E7l\u00FC bir sekt\u00F6r konfig\u00FCrasyon sistemi bulunmaktad\u0131r. A\u015Fa\u011F\u0131daki tablo mevcut yap\u0131n\u0131n katmanlar\u0131n\u0131 \u00F6zetler:"),

        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [2400, 3480, 3480],
          rows: [
            new TableRow({ children: [headerCell("Katman", 2400), headerCell("Dosya", 3480), headerCell("Sorumluluk", 3480)] }),
            new TableRow({ children: [
              cell("Enum", 2400, { bold: true }),
              cell("sector_config.dart", 3480, { fill: "F8F9FA" }),
              cell("SectorType: autoParts, general, technology, footwear", 3480),
            ]}),
            new TableRow({ children: [
              cell("Etiketler", 2400, { bold: true }),
              cell("SectorLabels (sector_config.dart)", 3480, { fill: "F8F9FA" }),
              cell("productName, categoryName, oemField, shelfField, variantField, barcodeLabel", 3480),
            ]}),
            new TableRow({ children: [
              cell("Alan G\u00F6r\u00FCn\u00FCrl\u00FC\u011F\u00FC", 2400, { bold: true }),
              cell("SectorFields (sector_config.dart)", 3480, { fill: "F8F9FA" }),
              cell("showOem, showVehicleCompat, showImei, showWarranty, showVariantSize vb.", 3480),
            ]}),
            new TableRow({ children: [
              cell("Provider", 2400, { bold: true }),
              cell("sector_provider.dart", 3480, { fill: "F8F9FA" }),
              cell("sectorConfigProvider, sectorTypeProvider (Riverpod)", 3480),
            ]}),
            new TableRow({ children: [
              cell("Kullan\u0131c\u0131 Modeli", 2400, { bold: true }),
              cell("user_model.dart", 3480, { fill: "F8F9FA" }),
              cell("User.sectorType: Backend JWT/company-settings", 3480),
            ]}),
          ]
        }),

        p("", { afterSpacing: 60 }),

        h2("1.1 Mevcut Sorunlar"),

        bullet([
          new TextRun({ text: "Hardcoded if/else dallanma: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "basic_info_step.dart ve product_detail_screen.dart dosyalar\u0131nda isParcaci / isGiyim kontrolleri do\u011Frudan widget a\u011Fac\u0131na g\u00F6m\u00FCl\u00FC.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Product Detail sabit 4 tab: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "T\u00FCm sekt\u00F6rlerde ayn\u0131 4 tab (Genel, OEM, \u00C7apraz Ref, Ara\u00E7 Uyumu) g\u00F6sterilir. Teknoloji sekt\u00F6r\u00FC i\u00E7in IMEI/garanti, giyim i\u00E7in beden/renk tab\u0131 bulunmaz.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Wizard a\u015Famalar\u0131 sekt\u00F6re duyars\u0131z: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Ad\u0131m say\u0131s\u0131 ve i\u00E7eri\u011Fi her sekt\u00F6rde ayn\u0131. Gereksiz alanlar g\u00F6r\u00FCn\u00FCr kal\u0131yor.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Yeni sekt\u00F6r eklemek g\u00FC\u00E7: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Her yeni sekt\u00F6r i\u00E7in 10+ dosyada if/else eklemek gerekir.", font: "Arial", size: 22 }),
        ]),

        // ═══════════ 2. HEDEFLENENMİMARİ ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("2. Hedeflenen Mimari: Section-Based Config"),

        p("Temel fikir: Her sekt\u00F6r\u00FCn \u00FCr\u00FCn ayr\u0131nt\u0131 ekran\u0131nda hangi b\u00F6l\u00FCmlerin (section), hangi s\u0131rayla, hangi alanlarla g\u00F6r\u00FCnece\u011Fini merkezi olarak tan\u0131mlamak. Widget\u2019lar sekt\u00F6rden ba\u011F\u0131ms\u0131z, genel ama\u00E7l\u0131 bile\u015Fenlerdir."),

        p("", { afterSpacing: 40 }),
        infoBox("Temel Prensip", "Yeni bir sekt\u00F6r eklemek = sadece SectorConfig\u2019e yeni bir SectorDetailSections listesi tan\u0131mlamak. Hi\u00E7bir widget dosyas\u0131 de\u011Fi\u015Fmez."),

        p("", { afterSpacing: 120 }),

        h2("2.1 Yeni Veri Yap\u0131lar\u0131"),

        h3("DetailSectionType Enum"),
        p("Her b\u00F6l\u00FCm tipini tan\u0131mlar:"),
        ...codeBlock([
          "enum DetailSectionType {",
          "  generalInfo,        // Temel bilgi kart\u0131 (t\u00FCm sekt\u00F6rler)",
          "  pricing,            // Fiyat bilgileri",
          "  stockInfo,          // Stok ve depo",
          "  variants,           // Varyant listesi",
          "  oemNumbers,         // OEM numaralar\u0131 (parçac\u0131)",
          "  crossReferences,    // Çapraz referanslar (parçac\u0131)",
          "  vehicleCompat,      // Araç uyumu (parçac\u0131)",
          "  imeiSerial,         // IMEI/Seri no (teknoloji)",
          "  warranty,           // Garanti bilgisi (teknoloji)",
          "  sizeColor,          // Beden/renk matrisi (giyim)",
          "  fabricSeason,       // Kumaş/sezon (giyim)",
          "  barcodes,           // Barkod yönetimi",
          "  images,             // Ürün görselleri",
          "  customAttributes,   // Sektöre özel ek alanlar",
          "}",
        ]),

        p("", { afterSpacing: 80 }),

        h3("SectorDetailSection Model"),
        p("Her b\u00F6l\u00FCm\u00FCn konfig\u00FCrasyonunu ta\u015F\u0131r:"),
        ...codeBlock([
          "class SectorDetailSection {",
          "  final DetailSectionType type;",
          "  final String title;          // Bölüm başlığı",
          "  final IconData icon;         // Bölüm ikonu",
          "  final bool isTab;            // Tab mı, inline section mı?",
          "  final bool collapsible;      // Açılır/kapanır mı?",
          "  final bool defaultExpanded;  // Varsayılan açık mı?",
          "  final int sortOrder;         // Sıralama",
          "  final List<String> fields;   // Gösterilecek alanlar",
          "  final bool editable;         // Düzenlenebilir mi?",
          "}",
        ]),

        p("", { afterSpacing: 80 }),

        h3("SectorConfig\u2019e Entegrasyon"),
        ...codeBlock([
          "class SectorConfig {",
          "  final SectorType type;",
          "  final SectorLabels labels;",
          "  final SectorFields fields;",
          "  // ... mevcut alanlar ...",
          "",
          "  // YENİ",
          "  final List<SectorDetailSection> detailSections;",
          "  final List<SectorDetailSection> wizardSteps;",
          "",
          "  // Yardımcı getter'lar",
          "  List<SectorDetailSection> get tabs =>",
          "      detailSections.where((s) => s.isTab).toList();",
          "  List<SectorDetailSection> get inlineSections =>",
          "      detailSections.where((s) => !s.isTab).toList();",
          "}",
        ]),

        // ═══════════ 2.2 SEKTÖR TANIMLARI ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        h2("2.2 Sekt\u00F6r Ba\u015F\u0131na B\u00F6l\u00FCm Tan\u0131mlar\u0131"),

        p("A\u015Fa\u011F\u0131daki tablo, her sekt\u00F6r\u00FCn \u00FCr\u00FCn ayr\u0131nt\u0131 ekran\u0131nda g\u00F6r\u00FCnecek b\u00F6l\u00FCmleri ve tiplerini (tab vs. inline) g\u00F6sterir:"),

        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [2600, 1690, 1690, 1690, 1690],
          rows: [
            new TableRow({ children: [
              headerCell("B\u00F6l\u00FCm", 2600),
              headerCell("Parçac\u0131", 1690),
              headerCell("Genel", 1690),
              headerCell("Teknoloji", 1690),
              headerCell("Giyim", 1690),
            ]}),
            // Rows
            ...([
              ["Genel Bilgi", "Tab", "Tab", "Tab", "Tab"],
              ["Fiyatland\u0131rma", "Inline", "Inline", "Inline", "Inline"],
              ["Stok / Depo", "Inline", "Inline", "Inline", "Inline"],
              ["Varyantlar", "Tab", "Tab", "Tab", "Tab"],
              ["OEM Numaralar\u0131", "Tab", "\u2014", "\u2014", "\u2014"],
              ["\u00C7apraz Referans", "Tab", "\u2014", "\u2014", "\u2014"],
              ["Ara\u00E7 Uyumu", "Tab", "\u2014", "\u2014", "\u2014"],
              ["IMEI / Seri No", "\u2014", "\u2014", "Tab", "\u2014"],
              ["Garanti Bilgisi", "\u2014", "\u2014", "Inline", "\u2014"],
              ["Beden / Renk Matrisi", "\u2014", "\u2014", "\u2014", "Tab"],
              ["Kuma\u015F / Sezon", "\u2014", "\u2014", "\u2014", "Inline"],
              ["Barkodlar", "Inline", "Inline", "Inline", "Inline"],
              ["G\u00F6rseller", "Inline", "Inline", "Inline", "Inline"],
            ]).map(row => new TableRow({ children: [
              cell(row[0], 2600, { bold: true }),
              cell(row[1], 1690, { fill: row[1] === "Tab" ? "E8F5E9" : row[1] === "Inline" ? "E3F2FD" : "F5F5F5", color: row[1] === "\u2014" ? "BBBBBB" : "333333" }),
              cell(row[2], 1690, { fill: row[2] === "Tab" ? "E8F5E9" : row[2] === "Inline" ? "E3F2FD" : "F5F5F5", color: row[2] === "\u2014" ? "BBBBBB" : "333333" }),
              cell(row[3], 1690, { fill: row[3] === "Tab" ? "E8F5E9" : row[3] === "Inline" ? "E3F2FD" : "F5F5F5", color: row[3] === "\u2014" ? "BBBBBB" : "333333" }),
              cell(row[4], 1690, { fill: row[4] === "Tab" ? "E8F5E9" : row[4] === "Inline" ? "E3F2FD" : "F5F5F5", color: row[4] === "\u2014" ? "BBBBBB" : "333333" }),
            ]})),
          ]
        }),

        p("", { afterSpacing: 60 }),
        p([
          new TextRun({ text: "Ye\u015Fil (Tab): ", bold: true, font: "Arial", size: 20, color: "2E7D32" }),
          new TextRun({ text: "Ayr\u0131 bir sekme olarak g\u00F6r\u00FCn\u00FCr.  ", font: "Arial", size: 20 }),
          new TextRun({ text: "Mavi (Inline): ", bold: true, font: "Arial", size: 20, color: "1565C0" }),
          new TextRun({ text: "Sekme i\u00E7inde kart olarak g\u00F6r\u00FCn\u00FCr.  ", font: "Arial", size: 20 }),
          new TextRun({ text: "\u2014: ", bold: true, font: "Arial", size: 20, color: "999999" }),
          new TextRun({ text: "Bu sekt\u00F6rde g\u00F6r\u00FCnmez.", font: "Arial", size: 20 }),
        ]),

        // ═══════════ 3. WIDGET MİMARİSİ ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("3. Widget Mimarisi"),

        h2("3.1 Section Widget Registry"),

        p("Her DetailSectionType i\u00E7in bir widget builder kaydedilir. Bu registry pattern sayesinde yeni b\u00F6l\u00FCm tipleri eklemek tek sat\u0131rl\u0131k i\u015Ftir:"),

        ...codeBlock([
          "// lib/core/config/section_widget_registry.dart",
          "",
          "typedef SectionWidgetBuilder = Widget Function(",
          "  BuildContext context,",
          "  Map<String, dynamic> product,",
          "  SectorDetailSection section,",
          ");",
          "",
          "final sectionWidgetRegistry = <DetailSectionType, SectionWidgetBuilder>{",
          "  DetailSectionType.generalInfo:     (ctx, p, s) => GeneralInfoSection(product: p, section: s),",
          "  DetailSectionType.pricing:         (ctx, p, s) => PricingSection(product: p, section: s),",
          "  DetailSectionType.stockInfo:       (ctx, p, s) => StockInfoSection(product: p, section: s),",
          "  DetailSectionType.variants:        (ctx, p, s) => VariantsSection(product: p, section: s),",
          "  DetailSectionType.oemNumbers:      (ctx, p, s) => OemSection(product: p, section: s),",
          "  DetailSectionType.crossReferences: (ctx, p, s) => CrossRefSection(product: p, section: s),",
          "  DetailSectionType.vehicleCompat:   (ctx, p, s) => VehicleCompatSection(product: p, section: s),",
          "  DetailSectionType.imeiSerial:      (ctx, p, s) => ImeiSerialSection(product: p, section: s),",
          "  DetailSectionType.warranty:        (ctx, p, s) => WarrantySection(product: p, section: s),",
          "  DetailSectionType.sizeColor:       (ctx, p, s) => SizeColorMatrixSection(product: p, section: s),",
          "  DetailSectionType.fabricSeason:    (ctx, p, s) => FabricSeasonSection(product: p, section: s),",
          "  DetailSectionType.barcodes:        (ctx, p, s) => BarcodesSection(product: p, section: s),",
          "  DetailSectionType.images:          (ctx, p, s) => ImagesSection(product: p, section: s),",
          "};",
        ]),

        p("", { afterSpacing: 80 }),

        h2("3.2 Yeniden Yap\u0131land\u0131r\u0131lan ProductDetailScreen"),

        p("Mevcut 4 sabit tab yerine, sekt\u00F6r konfig\u00FCrasyonundan dinamik tab ve inline section \u00FCretilir:"),

        ...codeBlock([
          "// product_detail_screen.dart (yeni build metodu)",
          "",
          "final cfg = ref.watch(sectorConfigProvider);",
          "final tabs = cfg.detailSections.where((s) => s.isTab).toList();",
          "final inlineSections = cfg.detailSections.where((s) => !s.isTab).toList();",
          "",
          "TabBar(",
          "  tabs: tabs.map((t) => Tab(icon: Icon(t.icon), text: t.title)).toList(),",
          "),",
          "TabBarView(",
          "  children: tabs.map((tab) {",
          "    final builder = sectionWidgetRegistry[tab.type];",
          "    return builder!(context, _product!, tab);",
          "  }).toList(),",
          "),",
          "",
          "// Inline sections: Tab içeriğinin altına eklenir",
          "...inlineSections.map((section) {",
          "  final builder = sectionWidgetRegistry[section.type];",
          "  if (section.collapsible) {",
          "    return CollapsibleCard(",
          "      title: section.title,",
          "      icon: section.icon,",
          "      defaultExpanded: section.defaultExpanded,",
          "      child: builder!(context, _product!, section),",
          "    );",
          "  }",
          "  return builder!(context, _product!, section);",
          "}),",
        ]),

        // ═══════════ 4. DOSYA YAPISI ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("4. Dosya Yap\u0131s\u0131"),

        p("Yeni ve de\u011Fi\u015Fen dosyalar\u0131n a\u011Fa\u00E7 g\u00F6r\u00FCn\u00FCm\u00FC:"),

        ...codeBlock([
          "lib/",
          "\u251C\u2500\u2500 core/",
          "\u2502   \u251C\u2500\u2500 config/",
          "\u2502   \u2502   \u251C\u2500\u2500 sector_config.dart          [GUNCELLEME]  +detailSections, +wizardSteps",
          "\u2502   \u2502   \u251C\u2500\u2500 detail_section_type.dart    [YENI]  Enum + SectorDetailSection model",
          "\u2502   \u2502   \u2514\u2500\u2500 section_widget_registry.dart [YENI]  Type \u2192 Widget mapping",
          "\u2502   \u2514\u2500\u2500 widgets/",
          "\u2502       \u2514\u2500\u2500 collapsible_card.dart        [YENI]  Acilir/kapanir section wrapper",
          "\u251C\u2500\u2500 screens/",
          "\u2502   \u2514\u2500\u2500 inventory/",
          "\u2502       \u251C\u2500\u2500 product_detail_screen.dart    [GUNCELLEME]  Dinamik tab/section uretimi",
          "\u2502       \u2514\u2500\u2500 sections/                     [YENI KLASOR]",
          "\u2502           \u251C\u2500\u2500 general_info_section.dart",
          "\u2502           \u251C\u2500\u2500 pricing_section.dart",
          "\u2502           \u251C\u2500\u2500 stock_info_section.dart",
          "\u2502           \u251C\u2500\u2500 variants_section.dart",
          "\u2502           \u251C\u2500\u2500 oem_section.dart",
          "\u2502           \u251C\u2500\u2500 cross_ref_section.dart",
          "\u2502           \u251C\u2500\u2500 vehicle_compat_section.dart",
          "\u2502           \u251C\u2500\u2500 imei_serial_section.dart      [YENI]",
          "\u2502           \u251C\u2500\u2500 warranty_section.dart          [YENI]",
          "\u2502           \u251C\u2500\u2500 size_color_matrix_section.dart [YENI]",
          "\u2502           \u251C\u2500\u2500 fabric_season_section.dart     [YENI]",
          "\u2502           \u251C\u2500\u2500 barcodes_section.dart",
          "\u2502           \u2514\u2500\u2500 images_section.dart",
          "\u2514\u2500\u2500 providers/",
          "    \u2514\u2500\u2500 sector_provider.dart          [GUNCELLEME]  detailSections uretimi",
        ]),

        // ═══════════ 5. KAÇINILACAK ANTİ-PATTERNLER ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("5. Ka\u00E7\u0131n\u0131lacak Anti-Pattern\u2019ler"),

        p("A\u015Fa\u011F\u0131daki tabloda, her anti-pattern\u2019in ne oldu\u011Fu, neden sak\u0131ncal\u0131 oldu\u011Fu ve do\u011Fru alternatifi a\u00E7\u0131klan\u0131r:"),

        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [3120, 3120, 3120],
          rows: [
            new TableRow({ children: [
              headerCell("Anti-Pattern", 3120),
              headerCell("Neden Sak\u0131ncal\u0131?", 3120),
              headerCell("Do\u011Fru Yakla\u015F\u0131m", 3120),
            ]}),
            new TableRow({ children: [
              cell("Widget icinde if(isParcaci) / if(isGiyim) dallanmasi", 3120, { bold: true }),
              cell("Her yeni sektor 10+ dosyada degisiklik gerektirir. Tek bir sektor degisikligi digerlierini kirabilir.", 3120),
              cell("SectorDetailSections listesinden dinamik section uretimi. Widget\u2019lar sektorden bagimsiz.", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Tum sektor alanlarini tek Product modeline nullable olarak eklemek", 3120, { bold: true }),
              cell("Model sisir, null-check kabusu, 5. sektorde 40+ nullable alan.", 3120),
              cell("Sektor-spesifik alanlar ayri Map<String, dynamic> olarak saklanir, SectorConfig hangi alanlarin gosterilecegini belirler.", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Backend-driven JSON schema ile tam dinamik form", 3120, { bold: true }),
              cell("Flutter\u2019da performans/tip guvenligi sorunu. Validasyon karmasiklasir. Overengineering.", 3120),
              cell("Config-driven ama compile-time guvenli: Dart enum + factory. Backend sadece data, UI mantigi client\u2019ta.", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Her sektor icin ayri ekran dosyasi (AutoPartsDetailScreen, FootwearDetailScreen...)", 3120, { bold: true }),
              cell("Kod tekrari, ortak degisiklikler N ekranda N kez yapilir.", 3120),
              cell("Tek ProductDetailScreen + Section Registry. Farklilik widget\u2019da degil, config\u2019de.", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Sabit Tab sayisi (her zaman 4 tab)", 3120, { bold: true }),
              cell("Genel sektorde OEM ve Arac Uyumu sekmesi gereksiz; teknolojide IMEI sekmesi eksik.", 3120),
              cell("Tab listesi SectorConfig.detailSections\u2019tan uretilir. Her sektor kendi tab\u2019larini tanimlar.", 3120, { fill: "E8F5E9" }),
            ]}),
          ]
        }),

        // ═══════════ 6. UYGULAMA FAZLARI ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("6. Uygulama Fazlar\u0131"),

        h2("Faz 1: Temel Altyap\u0131 (Tahmini: 2-3 g\u00FCn)"),
        bullet("DetailSectionType enum ve SectorDetailSection modelini olustur"),
        bullet("SectorConfig\u2019e detailSections listesini ekle (4 sektor icin)"),
        bullet("Section Widget Registry olustur"),
        bullet("CollapsibleCard widget\u2019ini olustur"),
        bullet("Mevcut product_detail_screen.dart\u2019i dinamik tab/section uretimine cevir"),

        p("", { afterSpacing: 60 }),
        warningBox("Kritik Not", "Faz 1 sonunda mevcut islevsellik birebir korunmali. Yeni ozellik eklenmeden once refactoring tamamlanmali."),

        p("", { afterSpacing: 120 }),

        h2("Faz 2: Yeni Sekt\u00F6r B\u00F6l\u00FCmleri (Tahmini: 3-4 g\u00FCn)"),
        bullet("ImeiSerialSection: IMEI, seri no, cihaz kimligi alanlari (teknoloji)"),
        bullet("WarrantySection: Garanti baslangic/bitis, garanti turu, servis kayitlari (teknoloji)"),
        bullet("SizeColorMatrixSection: Beden x Renk grid gorunumu, stok durumu (giyim)"),
        bullet("FabricSeasonSection: Kumas tipi, karis orani, sezon, koleksiyon (giyim)"),
        bullet("Mevcut OemSection, CrossRefSection, VehicleCompatSection\u2019i ayri dosyalara tasi"),

        p("", { afterSpacing: 120 }),

        h2("Faz 3: Wizard Entegrasyonu (Tahmini: 2-3 g\u00FCn)"),
        bullet("SectorConfig.wizardSteps listesi ile urun ekleme adimlarini dinamiklestir"),
        bullet("basic_info_step.dart\u2019taki isParcaci/isGiyim dallanmalarini section-based yaklasima cevir"),
        bullet("Her sektor icin farkli adim sayisi ve icerigi (parcaci: 6, genel: 4, teknoloji: 5, giyim: 5)"),

        p("", { afterSpacing: 120 }),

        h2("Faz 4: POS ve Toplu Islem Entegrasyonu (Tahmini: 1-2 g\u00FCn)"),
        bullet("POS ekraninda sektor etiketlerini kullan (cfg.labels.productName)"),
        bullet("Toplu import sablonlarini sektore gore dinamiklestir"),
        bullet("Barkod tarama ipuclarini sektorun barcodeHint\u2019inden al"),

        // ═══════════ 7. TEST STRATEJİSİ ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("7. Test Stratejisi"),

        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [2340, 2340, 2340, 2340],
          rows: [
            new TableRow({ children: [headerCell("Test Tipi", 2340), headerCell("Kapsam", 2340), headerCell("Ara\u00E7", 2340), headerCell("\u00D6ncelik", 2340)] }),
            new TableRow({ children: [
              cell("Unit Test", 2340, { bold: true }),
              cell("SectorConfig factory\u2019leri, section filtreleme, registry lookup", 2340),
              cell("flutter_test", 2340),
              cell("Yuksek", 2340, { color: "C62828" }),
            ]}),
            new TableRow({ children: [
              cell("Widget Test", 2340, { bold: true }),
              cell("Her section widget\u2019i izole olarak, CollapsibleCard", 2340),
              cell("flutter_test + WidgetTester", 2340),
              cell("Yuksek", 2340, { color: "C62828" }),
            ]}),
            new TableRow({ children: [
              cell("Entegrasyon", 2340, { bold: true }),
              cell("4 farkli sektorle ProductDetailScreen tab/section dogrulamasi", 2340),
              cell("integration_test", 2340),
              cell("Orta", 2340, { color: "E65100" }),
            ]}),
            new TableRow({ children: [
              cell("Regresyon", 2340, { bold: true }),
              cell("Mevcut parcaci islevi degismeden calisiyor mu?", 2340),
              cell("Manuel QA + golden test", 2340),
              cell("Yuksek", 2340, { color: "C62828" }),
            ]}),
          ]
        }),

        p("", { afterSpacing: 120 }),
        infoBox("Golden Test Stratejisi", "Her sektor icin ProductDetailScreen\u2019in ekran goruntusu kaydedilir. Regresyon testlerinde bu goruntuler referans olarak kullanilir."),

        // ═══════════ 8. ORNEK CONFIG ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("8. \u00D6rnek: Teknoloji Sekt\u00F6r\u00FC Config"),

        p("A\u015Fa\u011F\u0131da teknoloji sekt\u00F6r\u00FC i\u00E7in tam bir detailSections tan\u0131m\u0131 verilmi\u015Ftir. Bu \u00F6rnek, di\u011Fer sekt\u00F6rlerin nas\u0131l tan\u0131mlanaca\u011F\u0131n\u0131 g\u00F6sterir:"),

        ...codeBlock([
          "factory SectorConfig.technology() => SectorConfig(",
          "  type: SectorType.technology,",
          "  // ... mevcut labels, fields, barcodeHint ...",
          "  detailSections: [",
          "    SectorDetailSection(",
          "      type: DetailSectionType.generalInfo,",
          "      title: 'Cihaz Bilgileri',",
          "      icon: Icons.devices,",
          "      isTab: true,",
          "      sortOrder: 0,",
          "      fields: ['name', 'sku', 'brand', 'category', 'description'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.imeiSerial,",
          "      title: 'IMEI / Seri No',",
          "      icon: Icons.fingerprint,",
          "      isTab: true,",
          "      sortOrder: 1,",
          "      fields: ['imei', 'serialNumber', 'macAddress'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.variants,",
          "      title: 'Renk Varyantlari',",
          "      icon: Icons.palette,",
          "      isTab: true,",
          "      sortOrder: 2,",
          "      fields: ['color', 'storage', 'ram'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.pricing,",
          "      title: 'Fiyat Bilgileri',",
          "      icon: Icons.attach_money,",
          "      isTab: false,  // Inline",
          "      collapsible: true,",
          "      defaultExpanded: true,",
          "      sortOrder: 10,",
          "      fields: ['purchasePrice', 'salePrice', 'taxRate'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.warranty,",
          "      title: 'Garanti Bilgisi',",
          "      icon: Icons.verified_user,",
          "      isTab: false,  // Inline",
          "      collapsible: true,",
          "      defaultExpanded: false,",
          "      sortOrder: 11,",
          "      fields: ['warrantyMonths', 'warrantyType', 'serviceRecords'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.stockInfo,",
          "      title: 'Stok Durumu',",
          "      icon: Icons.inventory_2,",
          "      isTab: false,",
          "      collapsible: true,",
          "      defaultExpanded: true,",
          "      sortOrder: 12,",
          "      fields: ['stock', 'warehouse', 'minStock'],",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.barcodes,",
          "      title: 'Barkod / IMEI',",
          "      icon: Icons.qr_code,",
          "      isTab: false,",
          "      collapsible: true,",
          "      defaultExpanded: false,",
          "      sortOrder: 13,",
          "    ),",
          "    SectorDetailSection(",
          "      type: DetailSectionType.images,",
          "      title: 'Gorseller',",
          "      icon: Icons.image,",
          "      isTab: false,",
          "      collapsible: true,",
          "      defaultExpanded: false,",
          "      sortOrder: 14,",
          "    ),",
          "  ],",
          ");",
        ]),

        // ═══════════ 9. ÖZET VE KARAR MATRISI ═══════════
        new Paragraph({ children: [new PageBreak()] }),
        heading("9. \u00D6zet ve Karar Matrisi"),

        p("Bu tasar\u0131m\u0131n temel avantajlar\u0131:"),

        bullet([
          new TextRun({ text: "A\u00E7\u0131k/Kapal\u0131 Prensibi: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Yeni sekt\u00F6r eklemek mevcut kodu de\u011Fi\u015Ftirmez, sadece yeni config tan\u0131m\u0131 eklenir.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Tek Sorumluluk: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Her section widget\u2019\u0131 yaln\u0131zca kendi alan\u0131n\u0131 g\u00F6sterir, sekt\u00F6r mant\u0131\u011F\u0131 bilmez.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Geriye Uyumluluk: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Mevcut SectorLabels ve SectorFields yap\u0131s\u0131 korunur, \u00FCst\u00FCne eklenir.", font: "Arial", size: 22 }),
        ]),
        bullet([
          new TextRun({ text: "Test Edilebilirlik: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Her section izole test edilebilir, config unit test ile do\u011Frulanabilir.", font: "Arial", size: 22 }),
        ]),

        p("", { afterSpacing: 120 }),

        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [3120, 3120, 3120],
          rows: [
            new TableRow({ children: [headerCell("Kriter", 3120), headerCell("Mevcut Yap\u0131", 3120), headerCell("Yeni Mimari", 3120)] }),
            new TableRow({ children: [
              cell("Yeni sektor ekleme suresi", 3120, { bold: true }),
              cell("2-3 gun (10+ dosya degisikligi)", 3120, { fill: "FFEBEE" }),
              cell("2-4 saat (1 config + opsiyonel yeni section)", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Regresyon riski", 3120, { bold: true }),
              cell("Yuksek (if/else dallanma)", 3120, { fill: "FFEBEE" }),
              cell("Dusuk (izole section\u2019lar)", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Kod tekrari", 3120, { bold: true }),
              cell("Orta-yuksek", 3120, { fill: "FFF8E1" }),
              cell("Minimal (registry + ortak card)", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Okunabilirlik", 3120, { bold: true }),
              cell("Zorlasiyor (buyuyen switch)", 3120, { fill: "FFEBEE" }),
              cell("Yuksek (deklaratif config)", 3120, { fill: "E8F5E9" }),
            ]}),
            new TableRow({ children: [
              cell("Compile-time guvenlik", 3120, { bold: true }),
              cell("Var (Dart enum)", 3120, { fill: "E8F5E9" }),
              cell("Var (Dart enum + factory)", 3120, { fill: "E8F5E9" }),
            ]}),
          ]
        }),

        p("", { afterSpacing: 180 }),

        p([
          new TextRun({ text: "Sonraki ad\u0131m: ", bold: true, font: "Arial", size: 22 }),
          new TextRun({ text: "Bu dok\u00FCman\u0131 inceleyip onaylad\u0131ktan sonra Faz 1 uygulanmaya ba\u015Flanabilir. Her faz sonunda \u00E7al\u0131\u015Fir durumda bir build elde edilecek \u015Fekilde ilerlenecektir.", font: "Arial", size: 22 }),
        ]),
      ]
    }
  ]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/sessions/adoring-serene-babbage/mnt/project_pos/Sektor_Urun_Ayrintilari_Tasarim_Plani.docx", buffer);
  console.log("Dokuman olusturuldu!");
});
