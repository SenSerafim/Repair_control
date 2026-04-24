#!/usr/bin/env bash
# Генерирует Dart API-клиент из backend/docs/openapi.v1.json.
# Требования: docker (для openapi-generator-cli).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MOBILE="$(cd "$HERE/.." && pwd)"
REPO="$(cd "$MOBILE/.." && pwd)"
SPEC="$REPO/backend/docs/openapi.v1.json"
OUT="$MOBILE/lib/api"

if [ ! -f "$SPEC" ]; then
    echo "OpenAPI spec not found: $SPEC" >&2
    echo "Run from backend/: npm run openapi:export" >&2
    exit 1
fi

echo "=== OpenAPI gen: $SPEC → $OUT ==="
rm -rf "$OUT"
mkdir -p "$OUT"

docker run --rm \
    -v "$SPEC":/spec.json:ro \
    -v "$OUT":/out \
    openapitools/openapi-generator-cli:v7.9.0 generate \
    -i /spec.json \
    -g dart-dio \
    -o /out \
    --skip-validate-spec \
    --additional-properties=pubName=repair_control_api,pubVersion=1.0.0,serializationLibrary=json_serializable,useEnumExtension=true,nullableFields=true

cd "$MOBILE"
dart pub get
dart run build_runner build --delete-conflicting-outputs

echo "=== Done: $(find "$OUT/lib" -name '*.dart' | wc -l) Dart files generated ==="
