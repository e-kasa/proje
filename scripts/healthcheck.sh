#!/usr/bin/env bash
# SEDCORE POS — Servis Sağlık Kontrolü
# Kullanım: bash scripts/healthcheck.sh
set -euo pipefail

TIMEOUT=120
INTERVAL=3
COMPOSE_DIR="${COMPOSE_DIR:-/opt/sedcore-pos}"

check_http() {
  local name=$1
  local url=$2
  local max_wait=${3:-$TIMEOUT}

  echo -n "[$name] kontrol ediliyor... "
  local elapsed=0
  while [ $elapsed -lt $max_wait ]; do
    if wget -qO- "$url" > /dev/null 2>&1; then
      echo "OK"
      return 0
    fi
    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
  done
  echo "HATA (${max_wait}s sonra zaman aşımı)"
  return 1
}

check_db() {
  echo -n "[postgres] kontrol ediliyor... "
  if docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T postgres \
      pg_isready -U ekalem -d ekalem > /dev/null 2>&1; then
    echo "OK"
    return 0
  fi
  echo "HATA"
  return 1
}

echo "=== SEDCORE POS — Sağlık Kontrolü ==="
echo ""

# Container durumu
echo "Container'lar:"
docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps
echo ""

FAILED=0

# DB
check_db || FAILED=1

# Java servisleri
check_http "config-server"       "http://localhost:8081/config-server/actuator/health"   $TIMEOUT || FAILED=1
check_http "security"            "http://localhost:8002/security/actuator/health"         $TIMEOUT || FAILED=1
check_http "pos-product-manager" "http://localhost:8001/product/actuator/health"          $TIMEOUT || FAILED=1
check_http "api-manager"         "http://localhost:8080/actuator/health"                  $TIMEOUT || FAILED=1

# Python servisi
check_http "ocr-service"         "http://localhost:8003/health"                           60       || FAILED=1

# nginx
check_http "nginx"               "http://localhost:80"                                    30       || FAILED=1

# Grafana
check_http "grafana"             "http://localhost:3000/api/health"                       60       || FAILED=1

echo ""
if [ $FAILED -eq 0 ]; then
  echo "=== Tüm servisler sağlıklı ==="
  exit 0
else
  echo "=== BAZI SERVİSLER BAŞARISIZ ==="
  echo "Log için: docker compose logs <servis-adı>"
  exit 1
fi
