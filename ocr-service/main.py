from contextlib import asynccontextmanager
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from ocr_engine import get_reader, extract_text
from invoice_parser import parse_invoice_text
import uvicorn
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)s  %(message)s")
log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama başlarken EasyOCR modelini yükle (ilk istekte değil)."""
    log.info("EasyOCR modeli yükleniyor — ilk kez çalıştırılıyorsa model indirme süresi 3-10 dk olabilir...")
    try:
        get_reader()          # ağır model burada yüklenir (blocking ama kasıtlı)
        log.info("EasyOCR modeli hazır ✓")
    except Exception as e:
        log.error("EasyOCR model yüklenemedi: %s", e)
        raise RuntimeError(f"EasyOCR başlatılamadı: {e}") from e
    yield
    log.info("OCR servisi kapatılıyor.")


app = FastAPI(title="SEDCORE OCR Service", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok", "model": "loaded"}


@app.post("/ocr/extract")
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
            "tableOnly": table_only
        }
    except Exception as e:
        log.error("OCR işlem hatası: %s", e, exc_info=True)
        raise HTTPException(500, f"OCR hatası: {str(e)}")


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
