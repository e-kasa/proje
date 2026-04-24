#!/usr/bin/env bash
# Generate Dart OpenAPI client from backend spec.
#
# Ön şart:
#   1. openapi-generator-cli kurulu (npm i -g @openapitools/openapi-generator-cli)
#      VEYA jar indir: https://github.com/OpenAPITools/openapi-generator
#   2. Backend çalışıyor VE pos-product-manager/scripts/export-openapi.sh çalıştırılmış
#      (son openapi.json target/openapi.json'de olmalı)
#
# Kullanım:
#   ./scripts/generate-api.sh              # son openapi.json'dan üret
#   REFRESH=1 ./scripts/generate-api.sh    # önce backend'den tekrar çek, sonra üret
#
# Çıkış: lib/api/generated/  (önceki içerik silinir)
#
# Aşamalı migration (plan agile-noodling-crown.md Sprint 4):
#   Faz A: AccountsHub list tek ekran typed client kullan
#   Faz B: Kalan accounts feature migrate
#   Faz C: Diğer feature'lar — ayrı PR'lar

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$(cd "${PROJECT_DIR}/../pos-product-manager" && pwd)"
SPEC_FILE="${BACKEND_DIR}/target/openapi.json"

cd "${PROJECT_DIR}"

# 1. Opsiyonel: backend'den yeniden çek
if [[ "${REFRESH:-0}" == "1" ]]; then
  echo "→ REFRESH=1 — backend'den openapi.json tekrar çekiliyor"
  bash "${BACKEND_DIR}/scripts/export-openapi.sh"
fi

if [[ ! -f "${SPEC_FILE}" ]]; then
  echo "✗ openapi.json bulunamadı: ${SPEC_FILE}"
  echo "  Önce backend'i çalıştır + export-openapi.sh (veya REFRESH=1 ile tekrar dene)"
  exit 1
fi

# 2. Önceki çıktıyı temizle
OUT_DIR="${PROJECT_DIR}/lib/api/generated"
echo "→ Temizleniyor: ${OUT_DIR}"
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# 3. Generator komutu tespit (npm wrapper veya direct jar)
if command -v openapi-generator-cli &> /dev/null; then
  GEN_CMD="openapi-generator-cli"
elif command -v npx &> /dev/null; then
  GEN_CMD="npx @openapitools/openapi-generator-cli"
else
  echo "✗ openapi-generator-cli bulunamadı."
  echo "  Kurulum: npm i -g @openapitools/openapi-generator-cli"
  exit 1
fi

echo "→ Generator: ${GEN_CMD}"
echo "→ Config:    openapi-generator-config.yaml"
echo "→ Input:     ${SPEC_FILE}"
echo "→ Output:    ${OUT_DIR}"

# 4. Generate
${GEN_CMD} generate -c "${PROJECT_DIR}/openapi-generator-config.yaml"

# 5. built_value + json_serializable için build_runner çalıştır
echo "→ build_runner (generated Dart code için)"
cd "${OUT_DIR}"
if [[ -f "pubspec.yaml" ]]; then
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs || true
fi

echo "✓ Typed client hazır: ${OUT_DIR}"
echo ""
echo "Kullanım için (Faz A):"
echo "  1. ana pubspec.yaml'a dependency ekle:"
echo "       sedcore_api:"
echo "         path: lib/api/generated"
echo "  2. flutter pub get"
echo "  3. Tek ekran için typed client import et (bkz. wiki/patterns/openapi-codegen-flutter)"
