FROM python:3.11-slim

WORKDIR /app

# Sistem bağımlılıkları (EasyOCR için)
RUN apt-get update && apt-get install -y \
    libglib2.0-0 libsm6 libxrender1 libxext6 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# EasyOCR model önden indir (startup hızı için)
RUN python -c "import easyocr; easyocr.Reader(['tr', 'en'], gpu=False)"

COPY . .

EXPOSE 8003
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003"]
