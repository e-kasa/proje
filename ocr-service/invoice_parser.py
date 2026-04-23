"""
Fatura metnini ürün kalemlerine ayırır.

PDFBox'tan (Java backend) ya da OCR'dan gelen tam PDF metnini alır:
  1. Tablo header + footer'ı tespit eder (sadece ürün tablosu aralığı)
  2. Header/footer parçalarını + firma başlığı + adres + toplam satırlarını atar
  3. Kalan her ürün satırından: ad, kod, miktar, birim, birim fiyat, KDV oranı,
     iskonto oranı ve satır toplamı regex ile çıkarır
  4. Heuristic ile doğru birim fiyatı seçer
     (KDV dahil: qty × unitPrice × (1 + vat/100) ≈ totalPrice)

Java DocumentAnalyzeServiceImpl.extractLineInfo'nun birebir Python karşılığı.
"""

import re
import logging
from typing import Optional

log = logging.getLogger(__name__)

# ── REGEX'LER (Java ile eşdeğer) ─────────────────────────────────────────────

# Satır başındaki sıra numarası: "1 ", "2. ", "01 " vb.
_ROW_NUM_PREFIX = re.compile(r'^\s*\d{1,3}[.\s]+')

# EAN13 barkod: tam olarak 13 rakam
_BARCODE_PATTERN = re.compile(r'\b(\d{13})\b')

# OEM: harf+rakam karışımı, 4-20 karakter
_OEM_PATTERN = re.compile(r'\b([A-Z0-9][A-Z0-9 .\-]{2,18}[A-Z0-9])\b')

# Birim: ADET, AD, KG, LT vb.
_UNIT_PATTERN = re.compile(
    r'\b(ADET|ADT|AD|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\b',
    re.IGNORECASE,
)

# Birime bitişik miktar: "140 Adet", "6 kg" → qty=140/6, unit=ADET/KG
_QTY_BEFORE_UNIT = re.compile(
    r'(\d{1,8}(?:[.,]\d{1,4})?)\s*(ADET|ADT|AD|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\b',
    re.IGNORECASE,
)

# KDV oranı: "%0", "%18", "18%", "% 18"
_VAT_PATTERN = re.compile(
    r'(?:%\s*(0|1|8|10|18|20)\b|\b(0|1|8|10|18|20)\s*%)'
)

# İskonto oranı: "İsk. %10", "%5 İnd"
_DISCOUNT_PATTERN = re.compile(
    r'(?:i[sş]k(?:onto)?\.?|i[nṅ]d(?:irim)?\.?)\s*%?\s*(\d{1,2}(?:[.,]\d{1,2})?)'
    r'|(\d{1,2}(?:[.,]\d{1,2})?)\s*%?\s*(?:i[sş]k(?:onto)?|i[nṅ]d(?:irim)?)',
    re.IGNORECASE,
)

# Türkçe format sayı — binlik nokta + virgül ondalık
_NUMBER_PATTERN = re.compile(r'\b\d{1,8}(?:\.\d{1,4})?\b')

# Tablo BAŞLANGICI — bu kelimelerden biri satırda geçince tablo açılmış kabul
_TABLE_HEADER_MARKERS = [
    r'\bmal\s*/?\s*hizmet\b',
    r'\bmal\s*ve\s*hizmet\b',
    r'\baçıklama\b',
    r'\baciklama\b',
    r'\bürün\s*(kodu|adı|adi)?\b',
    r'\burun\s*(kodu|adı|adi)?\b',
    r'\bürün\s*/\s*hizmet\b',
    r'\bhizmet\s*(cinsi|adı|adi)\b',
    r'\bcins[iı]\b',
    r'\bnevi\b',
    r'\bstok\s*(kodu|adı|adi)\b',
    r'\bmalzeme\s*(kodu|adı|adi)?\b',
    r'\bmiktar\b',
    r'\badet\b',
    r'\bbirim\s*fiyat',
    r'\bfiyat\s*(tl|try)?\b',
    r'\biskonto\s*(oran[ıi]?|%)?',
    r'\bi̇skonto\s*(oran[ıi]?|%)?',
    r'\bi[sş]k\.?\s*(oran[ıi]?|%)?',
    r'\bind(irim)?\.?\s*(oran[ıi]?|%)?',
    r'\bkdv\s*(oran[ıi]?|tutar[ıi]?|%)?',
    r'\botv\b',
    r'\bvergi\s*(oran[ıi]?|tutar[ıi]?)?',
    r'\btutar\b',
    r'\bsıra(\s*no)?\b',
    r'\bsira(\s*no)?\b',
    r's\.?\s*no\b',
]
_TABLE_HEADER_RE = [re.compile(p, re.IGNORECASE) for p in _TABLE_HEADER_MARKERS]

# Tablo SONU — satır başında bu varsa sonrası elenir
_TABLE_FOOTER_MARKERS = [
    r'mal\s*hizmet\s*toplam',
    r'toplam\s*i?skonto',
    r'toplam\s*iskonto',
    r'hesaplanan\s*kdv',
    r'vergiler\s*dahil',
    r'vergiler\s*dahil\s*toplam',
    r'ödenecek\s*tutar',
    r'odenecek\s*tutar',
    r'genel\s*toplam',
    r'ara\s*toplam',
    r'kdv\s*toplam',
    r'net\s*toplam',
    r'yaln[ıi]z',
    r'teşekkür',
    r'tesekkur',
    r'fatura\s*do[ğg]rulama',
    r'hesap\s*bilgileri',
    r'i?ade\s*eden',
    r'iade\s*edilen',
    r'iban\b',
    r'kuveyt\s*türk',
    r'e-arşiv\s*izni',
    r'e-arsiv\s*izni',
    r'bu\s*sat[ıi]ş',
]
_TABLE_FOOTER_RE = [re.compile(p, re.IGNORECASE) for p in _TABLE_FOOTER_MARKERS]

# Ürün SATIRI DEĞİL — satır içinde varsa at (telefon, VKN, adres, email vs.)
_NON_PRODUCT_MARKERS = [
    r'\btel\s*[:.]',
    r'\btelefon\s*[:.]',
    r'\bfax\s*[:.]',
    r'\bvkn\s*[:.]?',
    r'\btckn\s*[:.]?',
    r'\be[\-\s]?posta',
    r'\bemail\s*[:.]',
    r'\bweb\s*[:.]',
    r'\bhttp',
    r'\bwww\.',
    r'\bvergi\s*dairesi',
    r'\bmersis\b',
    r'\badres\s*[:.]',
    r'\balıc[ıi]\s*[:.]',
    r'\bsatıc[ıi]\s*[:.]',
    r'\bmüşteri\s*[:.]',
    r'\bmusteri\s*[:.]',
    r'\bfatura\s*no',
    r'\birsaliye\s*no',
    r'\bfatura\s*tarih',
    r'\bbelge\s*tarih',
    r'\bd[üu]zenlenme\s*tarih',
    r'\bd[üu]zenlenme\s*saati',
    r'\bsipariş\s*no',
    r'\bsiparis\s*no',
    r'\bvade\s*tarih',
    r'\bödeme\s*şekli',
    r'\bodeme\s*sekli',
    r'\bkargo\b',
    r'\bteslimat\b',
    r'\bsayfa\s*\d',
    r'\bettn\s*[:.]?',
    r'\bözelleştirme\s*no',
    r'\bozellestirme\s*no',
    r'\bsenaryo\s*[:.]?',
    r'\bfatura\s*tipi',
]
_NON_PRODUCT_RE = [re.compile(p, re.IGNORECASE) for p in _NON_PRODUCT_MARKERS]

# Ürün adı NON_PRODUCT_NAME_START — temizlenmiş adın başında bu varsa at
_NON_PRODUCT_NAME_START = re.compile(
    r'^\s*(no|oran[ıi]?|tutar[ıi]?|kdv|vergiler\s*dahil|'
    r'mal\s*hizmet\s*toplam|hesaplanan\s*kdv|toplam\s*i?skonto|'
    r'ödenecek|\u00f6denecek|genel\s*toplam|net\s*toplam|ara\s*toplam|'
    r'vergiler|ettn|belge|özelleştirme|ozellestirme|senaryo|fatura\s*tipi|'
    r'yaln[ıi]z|te[sş]ekk[uü]r|fatura\s*do[ğg]rulama|hesap\s*bilgileri|'
    r'iban|ali?c[ıi]|sati?c[ıi]|sayın|sayin|mali\s*iade|iade\s*eden|'
    r'ad[ıi]?|soyad[ıi]?|adres|imza|cinsi|nevi)(\s|:|$)',
    re.IGNORECASE,
)

# En az bir 3-harfli Unicode kelime olmalı (ürün adı gerekli)
_NAME_MIN_WORD = re.compile(r'\w{3,}', re.UNICODE)

# ── HEADER METADATA — fatura başlığı (no, tarih, satıcı) ─────────────────────
# Örnek: "FATURA NO: GER2025000030968", "Fatura No : ABC-123"
_INVOICE_NO_PATTERN = re.compile(
    r'\b(?:fatura|belge|i?rsaliye)\s*n[oO]\s*[:.\-]?\s*([A-Z0-9][A-Z0-9\-/_.]{3,30})',
    re.IGNORECASE,
)
# "FATURA TARİHİ: 15.04.2026", "15/04/2026"
_INVOICE_DATE_PATTERN = re.compile(
    r'\b(?:fatura|belge|d[üu]zenlenme|düzenlenme)\s*tarih[ii]?\s*[:.\-]?\s*(\d{1,2}[./\-]\d{1,2}[./\-]\d{2,4})',
    re.IGNORECASE,
)
# "SAYIN: ABC TEKSTİL LTD", "SATICI: XYZ" — bir sonraki ':' ya da satır sonuna kadar
_SUPPLIER_PATTERN = re.compile(
    r'\b(?:say[ıi]n|sat[ıi]c[ıi]|al[ıi]c[ıi]|fatura\s*eden|firma)\s*[:.\-]\s*([^\n:]{3,80})',
    re.IGNORECASE,
)


# ── YARDIMCI FONKSİYONLAR ────────────────────────────────────────────────────

def _normalize_number(raw: str) -> Optional[float]:
    """Türkçe format '1.234,56' → 1234.56 float."""
    if not raw:
        return None
    # Binlik noktayı kaldır: 1.234 → 1234, ama 1.5 gibi ondalıkları koru
    s = re.sub(r'(\d)\.(\d{3})', r'\1\2', raw)
    s = s.replace(',', '.')
    try:
        return float(s)
    except ValueError:
        return None


def _extract_numbers(text: str) -> list[float]:
    """Metinden tüm sayıları çıkar (Türkçe format dahil)."""
    # Önce binlik nokta + virgül ondalık normalize
    normalized = re.sub(r'(\d)\.(\d{3})', r'\1\2', text).replace(',', '.')
    nums = []
    for m in _NUMBER_PATTERN.finditer(normalized):
        try:
            v = float(m.group(0))
            if v > 0:
                nums.append(v)
        except ValueError:
            continue
    return nums


def _is_table_header(line: str) -> bool:
    """Satırda en az 3 tablo başlık keyword'ü varsa header kabul et."""
    if not line:
        return False
    matches = sum(1 for r in _TABLE_HEADER_RE if r.search(line))
    return matches >= 3


def _is_table_header_continuation(line: str) -> bool:
    """Header alt satırı: sayı yok + ≥1 header keyword + kısa satır."""
    if not line or len(line) > 80:
        return False
    if re.search(r'\d+[.,]\d+', line):
        return False
    return any(r.search(line) for r in _TABLE_HEADER_RE)


def _is_table_footer(line: str) -> bool:
    """Satırda (veya başında) footer keyword varsa footer kabul et."""
    lower = line.lower().strip()
    # Baştaki sayı/para/tire karakterlerini temizle (sağ-hizalı sayı senaryosu)
    stripped = re.sub(r'^[\d.,\s\-–—₺$€]+(tl|try|usd|eur)?\s*', '', lower).strip()
    for r in _TABLE_FOOTER_RE:
        if r.search(lower) or r.search(stripped):
            return True
    return False


def _is_non_product_line(line: str) -> bool:
    """Telefon, VKN, email, fatura no vs. satırları — ürün değil."""
    lower = line.lower()
    return any(r.search(lower) for r in _NON_PRODUCT_RE)


def _parse_header_metadata(lines: list[str], header_idx: int) -> dict:
    """
    Header satırından ÖNCEKİ satırlarda fatura no, tarih, satıcı adı ara.
    header_idx -1 ise tüm metnin ilk 40 satırında ara.

    Returns: {'invoiceNo': str|None, 'invoiceDate': str|None, 'supplierName': str|None}
    """
    meta = {'invoiceNo': None, 'invoiceDate': None, 'supplierName': None}
    scan_end = header_idx if header_idx > 0 else min(40, len(lines))
    scan_lines = lines[:scan_end]
    blob = '\n'.join(scan_lines)

    m = _INVOICE_NO_PATTERN.search(blob)
    if m:
        meta['invoiceNo'] = m.group(1).strip()

    m = _INVOICE_DATE_PATTERN.search(blob)
    if m:
        meta['invoiceDate'] = m.group(1).strip()

    m = _SUPPLIER_PATTERN.search(blob)
    if m:
        name = m.group(1).strip()
        # "ABC TEKSTİL LTD\n" gibi alt satırda kalmış kısımları kes
        name = re.split(r'\s{2,}|\n', name)[0].strip()
        # Kısa kelimeleri (LTD, ŞTI vb.) koru ama tel/vkn satırlarını filtrele
        if len(name) >= 3 and not re.search(r'\d{10,}', name):
            meta['supplierName'] = name[:80]

    return meta


def _detect_table_range(lines: list[str]) -> tuple[int, int]:
    """
    Header satırını + footer satırını bul.
    Returns: (header_end_idx, footer_start_idx) — bu aralık DIŞI elenmeli.
    header_end_idx dahil → ürün satırları header_end_idx + 1'den başlar.
    """
    header_idx = -1
    for i, line in enumerate(lines):
        if _is_table_header(line):
            header_idx = i
            # Multi-line header: bir sonraki 3 satıra kadar devam edebilir
            for j in range(i + 1, min(i + 4, len(lines))):
                if _is_table_header_continuation(lines[j]):
                    header_idx = j
                else:
                    break
            break

    footer_idx = len(lines)
    search_start = header_idx + 1 if header_idx >= 0 else 0
    for i in range(search_start, len(lines)):
        if _is_table_footer(lines[i]):
            footer_idx = i
            break

    return header_idx, footer_idx


def _clean_product_name(raw: str, code: Optional[str]) -> str:
    """
    Ürün adından sayıları, birimi, para birimini ve yalın noktalama temizle.
    """
    s = raw
    if code:
        s = s.replace(code, ' ')
    # Türkçe format sayılar (binlik nokta + ondalık virgül)
    s = re.sub(r'\b\d+(?:[.,]\d+)*\b', ' ', s)
    # Birim + para birimi + iskonto kısaltmaları
    s = re.sub(
        r'\b(ADET|ADT|AD|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|'
        r'PCS|GR|GRAM|TL|TRY|USD|EUR|GBP|İSK|ISK|İND|IND)\b',
        ' ', s, flags=re.IGNORECASE,
    )
    # Para + özel semboller
    s = re.sub(r'[%₺$€£@#*"\']', ' ', s)
    # Yalın noktalama (başta/sonda/arada kalan virgül, nokta, tire)
    s = re.sub(r'(?:^|\s)[.,;:\-–—](?=\s|$)', ' ', s)
    # Whitespace normalize
    s = re.sub(r'\s+', ' ', s).strip()
    return s[:200]  # max 200 char


def _is_valid_product_dict(d: dict) -> bool:
    """Parse edilen dict'in gerçek ürün olup olmadığını doğrula."""
    name = d.get('name')
    if not name or len(name.strip()) < 3:
        return False
    if not _NAME_MIN_WORD.search(name):
        return False
    if _NON_PRODUCT_NAME_START.search(name):
        return False
    # 2+ footer keyword → footer satırı
    lower = name.lower()
    footer_hits = sum(1 for kw in
        ['toplam', 'tutar', 'oran', 'ödenecek', 'odenecek',
         'vergiler dahil', 'hesaplanan', 'iskonto']
        if kw in lower)
    if footer_hits >= 2:
        return False
    # En az bir sayısal alan
    return (d.get('quantity') is not None or
            d.get('unitPrice') is not None or
            d.get('totalPrice') is not None)


# ── ANA PARSE FONKSİYONU ─────────────────────────────────────────────────────

def _parse_product_line(line: str) -> Optional[dict]:
    """
    Tek bir ürün satırını parse eder.
    Returns: dict {name, code, quantity, unit, unitPrice, vatRate, discountRate, totalPrice}
             veya None (satır parse edilemediyse)

    Java DocumentAnalyzeServiceImpl.extractLineInfo'nun birebir karşılığı.
    """
    # 0. Satır başı sıra numarasını temizle
    processed = _ROW_NUM_PREFIX.sub('', line.strip())
    if not processed:
        return None

    result = {
        'name': None, 'code': None, 'codeType': None,
        'quantity': None, 'unit': None,
        'unitPrice': None, 'totalPrice': None,
        'vatRate': None, 'discountRate': None,
    }

    # 1. EAN13 barkod
    m = _BARCODE_PATTERN.search(processed)
    if m:
        result['code'] = m.group(1)
        result['codeType'] = 'BARCODE'

    # 2. OEM kodu (barkod yoksa) — miktar+birim kalıntılarını reddet
    if not result['code']:
        upper = processed.upper()
        for m in _OEM_PATTERN.finditer(upper):
            candidate = m.group(1).strip()
            # Zorunlu: hem harf hem rakam + min 4 karakter
            if not (re.search(r'[A-Z]', candidate) and
                    re.search(r'[0-9]', candidate) and
                    len(candidate) >= 4):
                continue
            # Birim kelimesi içeriyorsa OEM değildir ("140 ADET" vb.)
            if _UNIT_PATTERN.search(candidate):
                continue
            # Para birimi içeriyorsa OEM değildir
            if re.search(r'\b(TL|TRY|USD|EUR|GBP)\b', candidate, re.IGNORECASE):
                continue
            result['code'] = candidate
            result['codeType'] = 'OEM'
            break

    # 3. Miktar + birim ("140 Adet")
    m = _QTY_BEFORE_UNIT.search(processed)
    if m:
        qty_str = m.group(1)
        result['quantity'] = _normalize_number(qty_str)
        result['unit'] = m.group(2).upper()

    # 4. Birim (qty ile birlikte bulunmadıysa)
    if not result['unit']:
        m = _UNIT_PATTERN.search(processed)
        if m:
            result['unit'] = m.group(1).upper()

    # 5. KDV oranı
    m = _VAT_PATTERN.search(processed)
    if m:
        vat_group = m.group(1) or m.group(2)
        try:
            result['vatRate'] = float(vat_group)
        except (ValueError, TypeError):
            pass

    # 5b. İskonto oranı
    m = _DISCOUNT_PATTERN.search(processed)
    if m:
        disc_group = m.group(1) or m.group(2)
        if disc_group:
            rate = _normalize_number(disc_group)
            if rate is not None and 0 <= rate <= 100:
                result['discountRate'] = rate

    # 6. Sayılar — KDV/iskonto % değerlerini ÖNCE temizle
    cleaned = processed
    cleaned = re.sub(r'%\s*\d{1,2}(?:[.,]\d{1,4})?', ' ', cleaned)
    cleaned = re.sub(r'\d{1,2}(?:[.,]\d{1,4})?\s*%', ' ', cleaned)

    numbers = _extract_numbers(cleaned)

    # Hariç tutulacaklar: miktar + KDV oranı + iskonto oranı
    exclusions = set()
    if result['quantity'] is not None: exclusions.add(result['quantity'])
    if result['vatRate'] is not None:  exclusions.add(result['vatRate'])
    if result['discountRate'] is not None: exclusions.add(result['discountRate'])

    # Miktar birimle bulunmadıysa integer + 1-9999 ilk sayıyı seç
    if result['quantity'] is None and numbers:
        for n in numbers:
            if n == int(n) and 1 <= n <= 9999:
                result['quantity'] = n
                exclusions.add(n)
                break

    prices = sorted(set(n for n in numbers if n > 0 and n not in exclusions))

    if prices:
        # totalPrice = en büyük (genelde satır toplamı)
        result['totalPrice'] = prices[-1]

        # unitPrice heuristic: qty × unitPrice ≈ totalPrice olmalı
        qty = result['quantity']
        total = result['totalPrice']
        vat = result['vatRate'] or 0

        if qty and qty > 0 and total:
            expected_net = total / qty
            expected_gross = total / (qty * (1 + vat / 100)) if vat > 0 else 0

            best = None
            best_delta = float('inf')
            for p in prices:
                if p == total:
                    continue  # total'ı atla
                d1 = abs(p - expected_net) / expected_net if expected_net > 0 else float('inf')
                d2 = abs(p - expected_gross) / expected_gross if expected_gross > 0 else float('inf')
                d = min(d1, d2)
                if d < best_delta:
                    best_delta = d
                    best = p

            if best is not None and best_delta <= 0.05:
                result['unitPrice'] = best
            elif len(prices) >= 2:
                # Heuristic başarısız → ortanca (median) fiyat
                result['unitPrice'] = prices[len(prices) // 2]
            elif prices:
                result['unitPrice'] = prices[0]
        elif prices:
            # Miktar yok — en küçük fiyat
            result['unitPrice'] = prices[0]

    # 7. Ürün adı — kodu, sayıları, birimi, parayı temizle
    name = _clean_product_name(processed, result['code'])
    if len(name) >= 3 and re.search(r'[a-zA-ZğüşıöçĞÜŞİÖÇİ]', name):
        result['name'] = name

    return result


def parse_invoice_text(text: str) -> dict:
    """
    PDF/OCR metnini alır, sadece ürün tablosunu parse eder.

    Returns:
        {
            'items': [{name, code, quantity, unit, unitPrice, vatRate,
                       discountRate, totalPrice}],
            'headerLine': int,       # -1 if not detected
            'footerLine': int,       # len(lines) if not found
            'skippedCount': int,
            'totalLines': int,
        }
    """
    if not text or not text.strip():
        return {'items': [], 'headerLine': -1, 'footerLine': 0,
                'skippedCount': 0, 'totalLines': 0}

    # Satırları ayır, boşları at
    raw_lines = text.split('\n')
    lines = [l for l in raw_lines if l and l.strip()]
    total_lines = len(lines)

    # Tablo aralığını tespit et
    header_idx, footer_idx = _detect_table_range(lines)
    # Header öncesi satırlarda fatura no / tarih / satıcı adı yakala
    metadata = _parse_header_metadata(lines, header_idx)
    log.info(
        "parse_invoice_text: %d satır, header=%d, footer=%d, meta=%s",
        total_lines, header_idx, footer_idx, metadata,
    )

    # Aralık içi satırları işle (header sonrası, footer öncesi)
    start = header_idx + 1 if header_idx >= 0 else 0
    candidates = lines[start:footer_idx]

    items = []
    skipped = 0
    for raw_line in candidates:
        line = raw_line.strip()
        if len(line) < 4:
            skipped += 1
            continue
        if _is_non_product_line(line):
            log.debug("SKIP non-product: %s", line)
            skipped += 1
            continue
        if _is_table_footer(line):  # aralık içinde kalmış footer parçası
            log.debug("SKIP footer-in-range: %s", line)
            skipped += 1
            continue

        parsed = _parse_product_line(line)
        if parsed is None or not _is_valid_product_dict(parsed):
            log.info("SKIP invalid: '%s' → %s", line, parsed)
            skipped += 1
            continue

        log.info(
            "ÜRÜN: '%s' → name=%r, qty=%s, unit=%s, price=%s, total=%s, vat=%s",
            line, parsed.get('name'), parsed.get('quantity'),
            parsed.get('unit'), parsed.get('unitPrice'),
            parsed.get('totalPrice'), parsed.get('vatRate'),
        )
        # Internal field'ları ayıkla (codeType dışa vermeye gerek yok)
        parsed.pop('codeType', None)
        items.append(parsed)

    return {
        'items': items,
        'headerLine': header_idx,
        'footerLine': footer_idx,
        'skippedCount': skipped,
        'totalLines': total_lines,
        'metadata': metadata,
    }
