import easyocr
import numpy as np
from PIL import Image
import io
import re
import threading
import logging

log = logging.getLogger(__name__)

_reader = None
_reader_lock = threading.Lock()


def get_reader() -> easyocr.Reader:
    """
    EasyOCR reader'ı döndürür.
    Thread-safe singleton — ilk çağrıda model indirilir/yüklenir.
    """
    global _reader
    if _reader is None:
        with _reader_lock:
            if _reader is None:          # double-checked locking
                log.info("easyocr.Reader(['tr', 'en'], gpu=False) başlatılıyor...")
                _reader = easyocr.Reader(['tr', 'en'], gpu=False)
                log.info("Reader hazır.")
    return _reader


# ── FATURA TABLO FİLTRELEME ──────────────────────────────────────────────────
# Amaç: OCR çıktısından SADECE ürün kalemlerini (Mal/Hizmet + Miktar +
# Birim Fiyatı + İskonto Oranı + KDV Oranı) korumak. Logo, firma başlığı,
# adres, telefon, vergi numarası, IBAN, imza, footer/dipnot satırları elenir.

# Tablo BAŞLANGICI — bu kelimelerden biri satırda geçince tablo açılmış kabul
# edilir. Eşleşen satırın KENDİSİ çıkarılır, sonraki satırlar değerlendirmeye
# alınır. Her belgede kolon adı farklı olabilir — kapsamlı liste.
_TABLE_HEADER_MARKERS = [
    # Ürün adı kolonu
    r'\bmal\s*/?\s*hizmet\b',
    r'\bmal\s*ve\s*hizmet\b',
    r'\baçıklama\b',
    r'\baciklama\b',
    r'\bürün\s*(kodu|adı|adi)?\b',
    r'\burun\s*(kodu|adı|adi)?\b',
    r'\bürün\s*/\s*hizmet\b',
    r'\burun\s*/\s*hizmet\b',
    r'\bhizmet\s*(cinsi|adı|adi)\b',
    r'\bcins[iı]\b',
    r'\bnevi\b',
    r'\bstok\s*(kodu|adı|adi)\b',
    r'\bmalzeme\s*(kodu|adı|adi)?\b',
    # Miktar / birim
    r'\bmiktar\b',
    r'\badet\b',
    r'\bbirim\b',
    # Fiyat
    r'\bbirim\s*fiyat',
    r'\bfiyat\s*(tl|try)?\b',
    # İskonto
    r'\biskonto\s*(oran[ıi]?|%)?',
    r'\bi̇skonto\s*(oran[ıi]?|%)?',
    r'\bi[sş]k\.?\s*(oran[ıi]?|%)?',
    r'\bind(irim)?\.?\s*(oran[ıi]?|%)?',
    # KDV / vergi
    r'\bkdv\s*(oran[ıi]?|tutar[ıi]?|%)?',
    r'\botv\b',
    r'\bvergi\s*(oran[ıi]?|tutar[ıi]?)?',
    # Tutar
    r'\btutar\b',
    r'\btoplam\s*(fiyat|tutar)?\b',  # "Toplam" sadece başlıksa — footer ile karışmasın
    # Sıra
    r'\bsıra(\s*no)?\b',
    r'\bsira(\s*no)?\b',
    r'\bs\.?\s*no\b',
    r'\bno\b',
]

# Tablo SONU — bu kelimelerden biri satır başına yakınsa, satır ve sonrası
# atılır. Para/rakam içeren footer satırları buradan elenir.
_TABLE_FOOTER_MARKERS = [
    r'\bmal\s*hizmet\s*toplam',
    r'\btoplam\s*i?skonto',
    r'\btoplam\s*iskonto',
    r'\bhesaplanan\s*kdv',
    r'\bvergiler\s*dahil',
    r'\bgenel\s*toplam',
    r'\bara\s*toplam',
    r'\bnet\s*toplam',
    r'\bödenecek',
    r'\bodenecek',
    r'\byaln[ıi]z',
    r'\bteşekkür',
    r'\btesekkur',
    r'\bfatura\s*do[ğg]rulama',
    r'\bhesap\s*bilgileri',
    r'\bimza\b',
    r'\bkaşe\b',
    r'\bkase\b',
    r'\bbanka\b',
    r'\biban\b',
]

# Ürün SATIRI DEĞİL — adres/firma/tedarikçi/alıcı bilgisi. İçerik ne olursa olsun
# elenir (tablo aralığında bile).
_NON_PRODUCT_MARKERS = [
    r'\btel\s*[:.]',
    r'\btelefon\s*[:.]',
    r'\bfax\s*[:.]',
    r'\bfaks\s*[:.]',
    r'\bvkn\s*[:.]?',
    r'\btckn\s*[:.]?',
    r'\btc\s*kimlik',
    r'\be[\-\s]?posta',
    r'\bemail\s*[:.]',
    r'\bweb\s*[:.]',
    r'\bhttp',
    r'\bwww\.',
    r'\bvergi\s*dairesi',
    r'\bmersis\b',
    r'\badres\s*[:.]',
    r'\balıcı\s*[:.]',
    r'\balici\s*[:.]',
    r'\bsatıcı\s*[:.]',
    r'\bsatici\s*[:.]',
    r'\bmüşteri\s*[:.]',
    r'\bmusteri\s*[:.]',
    r'\bfatura\s*no',
    r'\birsaliye\s*no',
    r'\bfatura\s*tarih',
    r'\bbelge\s*tarih',
    r'\bdüzenleme\s*tarih',
    r'\bduzenleme\s*tarih',
    r'\bsipariş\s*no',
    r'\bsiparis\s*no',
    r'\bvade\s*tarih',
    r'\bödeme\s*şekli',
    r'\bodeme\s*sekli',
    r'\bkargo\b',
    r'\bteslimat\b',
    r'\bsayfa\s*\d',
    r'\bpage\s*\d',
]

# Para formatı: 1.234,56 / 1234,56 / 1234.56 / %18 / vs.
_MONEY_PATTERN = re.compile(
    r'(?:\d{1,3}(?:[.\s]\d{3})+|\d+)[,.]\d{1,4}|%\s*\d{1,2}|\d+\s*%'
)
# Basit rakam
_DIGIT_PATTERN = re.compile(r'\d')


def _is_header_line(line_lower: str) -> bool:
    return any(re.search(pat, line_lower) for pat in _TABLE_HEADER_MARKERS)


def _is_footer_line(line_lower: str) -> bool:
    return any(re.search(pat, line_lower) for pat in _TABLE_FOOTER_MARKERS)


def _is_non_product_line(line_lower: str) -> bool:
    return any(re.search(pat, line_lower) for pat in _NON_PRODUCT_MARKERS)


def _looks_like_product_row(line: str) -> bool:
    """
    Ürün satırı kriteri:
    - En az 8 karakter uzunluğunda
    - En az bir para formatı (x,yz) VEYA en az iki ayrı rakam grubu
      (miktar + birim fiyat minimum)
    - Sadece tek tek rakamlardan oluşmamalı (VKN, telefon gibi)
    """
    if len(line.strip()) < 8:
        return False

    # En az bir para formatı varsa kesin ürün satırıdır
    if _MONEY_PATTERN.search(line):
        return True

    # Para formatı yok — en az 2 ayrı rakam grubu (miktar + fiyat)
    digit_groups = re.findall(r'\d+', line)
    if len(digit_groups) < 2:
        return False

    # Harf sayısı (ürün adı gerekli — sadece rakam satırları telefon/VKN)
    letter_count = sum(1 for c in line if c.isalpha())
    return letter_count >= 3


def _filter_product_lines(lines: list[str]) -> list[str]:
    """
    Ürün tablosu ayıklayıcı.

    Strateji:
    1. Tablo header'ını bul — o satırdan ÖNCEKİ her şeyi at (logo/adres/firma)
    2. Tablo footer'ını bul — o satırdan SONRAKİ her şeyi at (toplamlar/imza)
    3. Arada kalan satırlarda:
       - Non-product (telefon/VKN/adres/email) satırlarını at
       - looks_like_product_row kontrolünden geçenleri koru
    4. Header hiç bulunamazsa (çok temiz OCR çıktısı) → tüm satırlarda
       non-product + ürün satırı filtresi uygula
    """
    if not lines:
        return lines

    # 1. Header'ı ara
    header_idx = -1
    for i, line in enumerate(lines):
        if _is_header_line(line.lower()):
            header_idx = i
            break

    # 2. Footer'ı ara (header'dan sonraki alanda)
    footer_search_start = header_idx + 1 if header_idx >= 0 else 0
    footer_idx = len(lines)
    for i in range(footer_search_start, len(lines)):
        if _is_footer_line(lines[i].lower()):
            footer_idx = i
            break

    # 3. Filtrelenecek aralık
    start = header_idx + 1 if header_idx >= 0 else 0
    end = footer_idx
    candidate = lines[start:end]

    # 4. Non-product + product-row filtresi
    out: list[str] = []
    for line in candidate:
        low = line.lower()
        if _is_non_product_line(low):
            continue
        if _is_footer_line(low):  # aralık içinde kalmış footer parçası
            continue
        if _is_header_line(low):  # tekrar eden header (multi-page)
            continue
        if not _looks_like_product_row(line):
            continue
        out.append(line)

    return out


# ── METİN ÇIKARMA ────────────────────────────────────────────────────────────

def extract_text(image_bytes: bytes, table_only: bool = False) -> str:
    """
    Görüntü baytlarından metin çıkar.
    Satırlar top→bottom, left→right sırasında birleştirilir.

    table_only=True:
      Fatura tablosundan SADECE ürün kalemlerini döndürür.
      Logo, başlık, adres, firma bilgisi, telefon, vergi no, IBAN,
      fatura/irsaliye başlık bilgisi, toplam/imza/dipnot satırları elenir.
      Geride sadece Mal/Hizmet + Miktar + Birim Fiyat + İskonto + KDV
      değerlerini içeren satırlar kalır.
    """
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img_array = np.array(image)

    results = get_reader().readtext(img_array)

    # Her sonuç: (bbox, text, confidence)
    # Sıralama: y koordinatına göre (yukarıdan aşağıya)
    results_sorted = sorted(results, key=lambda r: r[0][0][1])

    # Aynı satırdaki metinleri birleştir (y farkı < 20 piksel = aynı satır)
    lines: list[str] = []
    current_line: list[tuple[float, str]] = []
    prev_y: float | None = None

    for bbox, text, conf in results_sorted:
        if conf < 0.3:          # Güven skoru düşükse atla (logo/dekor)
            continue
        y = bbox[0][1]
        if prev_y is None or abs(y - prev_y) < 20:
            current_line.append((bbox[0][0], text))
        else:
            current_line.sort(key=lambda t: t[0])
            lines.append('  '.join(t[1] for t in current_line))
            current_line = [(bbox[0][0], text)]
        prev_y = y

    if current_line:
        current_line.sort(key=lambda t: t[0])
        lines.append('  '.join(t[1] for t in current_line))

    if table_only:
        filtered = _filter_product_lines(lines)
        log.info(
            "OCR filter: %d ham satır → %d ürün satırı (fark: %d)",
            len(lines), len(filtered), len(lines) - len(filtered),
        )
        lines = filtered

    return '\n'.join(lines)
