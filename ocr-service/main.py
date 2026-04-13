from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from ocr_engine import extract_text
import uvicorn

app = FastAPI(title="SEDCORE OCR Service", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/ocr/extract")
async def ocr_extract(file: UploadFile = File(...)):
    """
    Görüntü yükle → metin döndür.
    Desteklenen: JPG, PNG, WEBP, BMP
    """
    allowed = {'image/jpeg', 'image/png', 'image/webp', 'image/bmp'}
    if file.content_type not in allowed:
        raise HTTPException(400, f"Desteklenmeyen format: {file.content_type}")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:  # 10 MB limit
        raise HTTPException(400, "Dosya 10 MB'dan büyük olamaz")

    try:
        text = extract_text(contents)
        lines = [l for l in text.split('\n') if l.strip()]
        return {
            "success": True,
            "text": text,
            "lineCount": len(lines),
            "lines": lines
        }
    except Exception as e:
        raise HTTPException(500, f"OCR hatası: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)
