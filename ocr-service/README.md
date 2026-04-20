# OCR Service — SEDCORE POS

Python FastAPI servisi. İki farklı iş yapar:

| Endpoint | Ne yapar | Bağımlılık |
|----------|----------|-----------|
| `POST /parse-text` | Java PDFBox'tan gelen PDF metnini alır → sadece ürün tablosunu parse eder | Minimum (4 paket, ~30 MB) |
| `POST /ocr/extract` | Görüntü / taranmış PDF'i OCR ile metne çevirir | + EasyOCR (~2 GB) |
| `GET /health` | Servis durumu + hangi endpoint'ler aktif | — |

**Port:** `8003` (Java backend `ocr.service.url` default'u)

---

## Hızlı başlangıç — Dijital PDF için (önerilen)

Dijital PDF'lerin parse'ı için **EasyOCR gerekli değil**. 4 hafif paket yeter:

```cmd
cd C:\Users\Win11\Documents\GitHub\proje\ocr-service
python -m pip install -r requirements-minimal.txt
python -m uvicorn main:app --port 8003
```

**Beklenen log:**
```
INFO  EasyOCR yüklü değil — /ocr/extract endpoint'i devre dışı.
INFO  /ocr/extract kaydedilmedi (bağımlılık eksik)
INFO  EasyOCR yok — sadece /parse-text aktif (dijital PDF parse için yeterli)
INFO  Application startup complete.
INFO  Uvicorn running on http://0.0.0.0:8003
```

Bu **normal** — dijital PDF akışı için gerekenler hazır.

### Doğrulama

Yeni bir cmd penceresinde:

```cmd
curl http://localhost:8003/health
```

Beklenen:
```json
{"status":"ok","endpoints":{"/parse-text":"available","/ocr/extract":"disabled (easyocr=False, multipart=True)"}}
```

---

## Tam kurulum — Taranmış PDF + görüntü OCR için

Taranmış PDF veya JPG/PNG fatura yükleyeceksen EasyOCR gerekli:

```cmd
cd C:\Users\Win11\Documents\GitHub\proje\ocr-service
python -m pip install -r requirements.txt
python -m uvicorn main:app --port 8003
```

**İlk çalıştırma:** EasyOCR Türkçe + İngilizce modelini indirir (~300 MB, 3-10 dk).

**Beklenen log (başarılı):**
```
INFO  EasyOCR modeli yükleniyor — ilk kez çalıştırılıyorsa 3-10 dk sürebilir...
INFO  easyocr.Reader(['tr', 'en'], gpu=False) başlatılıyor...
INFO  Reader hazır.
INFO  EasyOCR modeli hazır ✓
INFO  /ocr/extract kaydedildi ✓
INFO  Application startup complete.
```

---

## API kullanımı

### `POST /parse-text`

PDFBox'tan gelen tam PDF metnini alır, sadece ürün tablosunu parse eder.

**Request:**
```json
{"text": "Sıra Mal Hizmet Miktar Birim Fiyat...\n 1 GÖMLEK 140 Adet 454,55 TL %10,00 6.363,64 TL 70.000,01 TL\n..."}
```

**Response:**
```json
{
  "items": [
    {
      "name": "GÖMLEK",
      "code": null,
      "quantity": 140.0,
      "unit": "ADET",
      "unitPrice": 454.55,
      "totalPrice": 70000.01,
      "vatRate": 10.0,
      "discountRate": null
    }
  ],
  "headerLine": 0,
  "footerLine": 3,
  "skippedCount": 1,
  "totalLines": 5
}
```

### `POST /ocr/extract`

Multipart form upload. `file` field + opsiyonel `table_only=true` query.

```cmd
curl -X POST "http://localhost:8003/ocr/extract?table_only=true" -F "file=@invoice.jpg"
```

---

## Python 3.14 notu

Python 3.14 çok yeni olduğu için bazı paket wheels eksik olabilir. Hata alırsan:

```cmd
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r requirements-minimal.txt
```

Veya Python 3.12 kullan (en stabil).

---

## Sorun giderme

| Hata | Çözüm |
|------|-------|
| `ModuleNotFoundError: No module named 'uvicorn'` | `python -m pip install -r requirements-minimal.txt` |
| `Form data requires "python-multipart"` | `python -m pip install python-multipart` (veya minimal.txt kur) |
| `Port 8003 in use` | Başka bir port: `python -m uvicorn main:app --port 8013` + Java'da `ocr.service.url=http://localhost:8013` |
| `Connection refused` Java tarafında | Bu servis çalışmıyor. Terminal'de uvicorn log'unu kontrol et. |
| EasyOCR "model indirme" saatlerce sürüyor | İnternet bağlantısı yavaş — sabırla bekle, ya da minimum kurulumla devam et (taranmış PDF olmadığında gerekmez) |

---

## Geliştirici notu

`invoice_parser.py` tüm parse mantığını içerir — Java `DocumentAnalyzeServiceImpl.extractLineInfo`'nun Python karşılığı. Yeni fatura formatları:

- Yeni kolon başlığı (ör. "Ürün Cinsi") → `_TABLE_HEADER_MARKERS` listesine ekle
- Yeni footer ("Hesaplanan KDV") → `_TABLE_FOOTER_MARKERS`
- Yeni non-product pattern (ör. "Sipariş No") → `_NON_PRODUCT_MARKERS`

Değişiklik sonrası manuel test:

```cmd
python -c "from invoice_parser import parse_invoice_text; print(parse_invoice_text('...örnek metin...'))"
```
