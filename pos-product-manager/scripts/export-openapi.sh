#!/usr/bin/env bash
# Export OpenAPI schema from running backend to target/openapi.json.
#
# Kullanım:
#   1. Backend çalışıyor olmalı: mvn spring-boot:run (port 8001, context /product)
#   2. Bu script cURL ile /v3/api-docs endpoint'ini indirir
#
# Çıktı: pos-product-manager/target/openapi.json
#
# Flutter generate için: project_pos/scripts/generate-api.sh çalıştırıldığında bu dosyayı okur.

set -euo pipefail

HOST="${OPENAPI_HOST:-http://localhost:8001}"
# Spring context-path=/product altında springdoc /v3/api-docs path'i /product/v3/api-docs olur
URL="${HOST}/product/v3/api-docs"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/target"
OUT="${TARGET_DIR}/openapi.json"

mkdir -p "${TARGET_DIR}"

echo "→ Fetching OpenAPI spec from ${URL}"

http_status=$(curl -sS -o "${OUT}" -w "%{http_code}" "${URL}" || true)

if [[ "${http_status}" != "200" ]]; then
  echo "✗ HTTP ${http_status} — backend çalışıyor mu? (mvn spring-boot:run)"
  echo "  URL: ${URL}"
  rm -f "${OUT}"
  exit 1
fi

size=$(wc -c < "${OUT}")
echo "✓ Yazıldı: ${OUT} (${size} byte)"
