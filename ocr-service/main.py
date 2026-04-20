from contextlib import asynccontextmanager
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from invoice_parser import parse_invoice_text
import uvicorn
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)s  %(message)s")
log = logging.getLogger(__name__)

# ── OPSİYONEL BAĞIMLILIKLAR ──────────────────────────────────────────────────
# Bu servis iki yolu destekler:
#   1. /parse-text   → Java PDFBox metnini parse eder (dijital PDF için)
#                      Gerekli: fastapi + uvicorn + pydantic (minimum kurulum)
#   2. /ocr/extract  → Görüntü/taranmış PDF'i EasyOCR ile metne çevirir
#                      Gerekli: EasyOCR (torch, 1-2 GB) + python-multipart
#
# Eksik bağımlılıkta endpoint otomatik devre dışı kalır, servis yine başlar.

_easyocr_available = False
try:
    from ocr_engine import get_reader, extract_text
    _easyocr_available = True
except ImportError as _e:
    log.warning("EasyOCR yüklü değil — /ocr/extract endpoint'i devre dışı. "
                "Kurulum: pip install easyocr. Hata: %s", _e)

_multipart_available = False
try:
    import multipart  # noqa: F401 — python-multipart paketi
    _multipart_available = True
except ImportError:
    log.info("python-multipart yüklü değil — /ocr/extract endpoint'i devre dışı. "
             "Kurulum: pip install python-multipart")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama başlarken EasyOCR modelini yükle (mevcutsa)."""
    if _easyocr_available:
        log.info("EasyOCR modeli yükleniyor — ilk kez çalıştırılıyorsa 3-10 dk sürebilir...")
        try:
            get_reader()
            log.info("EasyOCR modeli hazır ✓")
        except Exception as e:
            log.error("EasyOCR model yüklenemedi: %s — /ocr/extract kapalı", e)
    else:
        log.info("EasyOCR yok — sadece /parse-text aktif (dijital PDF parse için yeterli)")
    yield
    log.info("OCR servisi kapatılıyor.")


app = FastAPI(title="SEDCORE OCR Service", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "endpoints": {
            "/parse-text": "available",
            "/ocr/extract": "available" if (_easyocr_available and _multipart_available)
                            else f"disabled (easyocr={_easyocr_available}, "
                                 f"multipart={_multipart_available})",
        },
    }


async def ocr_extract(file: UploadFile = File(...), table_only: bool = False):
    """
    Görüntü yükle → metin döndür.
    Desteklenen: JPG, PNG, WEBP, BMP

    table_only=true: Sadece sayı içeren satırları döndürür.
    Fatura başlığı, adres, firma bilgisi gibi saf metin satırları elenir.
    """
    allowed = {'image/jpeg', 'image/png', 'image/webp', 'image/bmp'}
    if file.content_type not in allowed:
        raise HTTPException(400, f"Desteklenmeyen format: {file.content_type}")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:  # 10 MB limit
        raise HTTPException(400, "Dosya 10 MB'dan büyük olamaz")

    try:
        text = extract_text(contents, table_only=table_only)
        lines = [l for l in text.split('\n') if l.strip()]
        return {
            "success": True,
            "text": text,
            "lineCount": len(lines),
            "lines": lines,
            "tableOnly": table_only,
        }
    except Exception as e:
        log.error("OCR işlem hatası: %s", e, exc_info=True)
        raise HTTPException(500, f"OCR hatası: {str(e)}")


# /ocr/extract sadece EasyOCR + python-multipart birlikte varsa register edilir.
# Aksi halde endpoint hiç yoktur — FastAPI multipart-is-installed assertion'ı
# modül yüklenmeden tetiklenmez, servis temiz başlar.
if _easyocr_available and _multipart_available:
    app.post("/ocr/extract")(ocr_extract)
    log.info("/ocr/extract kaydedildi ✓")
else:
    log.info("/ocr/extract kaydedilmedi (bağımlılık eksik)")


class ParseTextRequest(BaseModel):
    """PDFBox'tan gelen ham PDF metni. Python parse sonucu items[] döner."""
    text: str


@app.post("/parse-text")
async def parse_text(request: ParseTextRequest):
    """
    PDF metnini alır, SADECE ürün tablosunu parse eder.

    Java PDFBox'tan çıkarılan metni:
      - header + footer tespit et (sadece ürün tablosu aralığı)
      - firma başlığı + adres + toplam/imza/footer satırları elenir
      - her ürün satırını regex ile parse et (isim/kod/miktar/fiyat/KDV/iskonto)

    Returns: {items, headerLine, footerLine, skippedCount, totalLines}
    """
    if not request.text or not request.text.strip():
        raise HTTPException(400, "text alanı boş olamaz")

    try:
        result = parse_invoice_text(request.text)
        log.info(
            "parse_text: %d satır → %d ürün (atılan: %d)",
            result["totalLines"],
            len(result["items"]),
            result["skippedCount"],
        )
        return result
    except Exception as e:
        log.error("parse_text hatası: %s", e, exc_info=True)
        raise HTTPException(500, f"Parse hatası: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)
