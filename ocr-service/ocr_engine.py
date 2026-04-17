import easyocr
import numpy as np
from PIL import Image
import io

# Servis başladığında bir kez yüklenir (ağır model)
_reader = None


def get_reader():
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(['tr', 'en'], gpu=False)
    return _reader


def extract_text(image_bytes: bytes, table_only: bool = False) -> str:
    """
    Görüntü baytlarından metin çıkar.
    Satırlar top→bottom, left→right sırasında birleştirilir.

    table_only=True: Sadece sayı içeren satırları döndürür (ürün tablosu satırları).
    Fatura başlığı, adres, firma bilgisi gibi sadece metin satırları elenir.
    """
    import re

    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img_array = np.array(image)

    results = get_reader().readtext(img_array)

    # Her sonuç: (bbox, text, confidence)
    # Sıralama: y koordinatına göre (yukarıdan aşağıya)
    results_sorted = sorted(results, key=lambda r: r[0][0][1])

    # Aynı satırdaki metinleri birleştir (y farkı < 20 piksel = aynı satır)
    lines = []
    current_line = []
    prev_y = None

    for bbox, text, conf in results_sorted:
        if conf < 0.3:  # Güven skoru düşükse atla
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
        # Sadece sayı içeren satırları tut (ürün tablosu satırları)
        # Adres, başlık, firma adı gibi sadece metin satırları elenir
        lines = [l for l in lines if re.search(r'\d', l)]

    return '\n'.join(lines)
