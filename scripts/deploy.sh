#!/usr/bin/env bash
# SEDCORE POS — Sunucu İlk Kurulum Scripti
# Tek seferlik çalıştırılır: bash scripts/deploy.sh
set -euo pipefail

INSTALL_DIR="/opt/sedcore-pos"
REPO_URL="https://github.com/GITHUB_KULLANICI/REPO_ADI.git"   # <-- güncelle

echo "=== SEDCORE POS — Sunucu Kurulumu ==="

# 1. Docker kur (Ubuntu 24.04)
if ! command -v docker &>/dev/null; then
  echo "Docker kuruluyor..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  echo "Docker kuruldu. Grup değişikliği için yeniden oturum açmanız gerekebilir."
  echo "Bu script'i tekrar çalıştırın."
  exit 0
fi

# 2. Proje dizini
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER":"$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 3. Repo klonla
if [ ! -d ".git" ]; then
  git clone "$REPO_URL" .
else
  git pull origin main
fi

# 4. Ortam dosyası
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo ""
  echo "======================================================="
  echo "  ÖNEMLİ: .env dosyasını düzenleyin!"
  echo "    nano $INSTALL_DIR/.env"
  echo ""
  echo "  Doldurun:"
  echo "    POSTGRES_PASSWORD, JWT_SECRET, GRAFANA_ADMIN_PASSWORD"
  echo "    GHCR_USERNAME, GHCR_TOKEN"
  echo "======================================================="
  echo ""
  echo ".env düzenlendikten sonra tekrar çalıştırın."
  exit 0
fi

# 5. GHCR login
source .env
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin

# 7. Image'ları çek ve başlat
docker compose pull
docker compose up -d

echo ""
echo "=== Kurulum tamamlandı ==="
docker compose ps
echo ""
echo "Servis adresleri:"
echo "  Uygulama : http://$(hostname -I | awk '{print $1}')/"
echo "  Grafana  : http://$(hostname -I | awk '{print $1}')/grafana/"
echo "  Prometheus: http://$(hostname -I | awk '{print $1}'):9090/"
