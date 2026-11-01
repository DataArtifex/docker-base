#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-dartfx/docker-base:latest}"

echo "=== Verifying Docker Image: ${IMAGE_NAME} ==="

# 1. Check system utilities
echo -n "Checking curl... "
docker run --rm "${IMAGE_NAME}" curl --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

echo -n "Checking jq... "
docker run --rm "${IMAGE_NAME}" jq --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

# 2. Check full-featured qsv binary installation
echo -n "Checking qsv version... "
docker run --rm "${IMAGE_NAME}" qsv --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

echo -n "Checking qsv polars engine (sqlp)... "
docker run --rm "${IMAGE_NAME}" qsv sqlp --help >/dev/null && echo "OK" || { echo "FAILED (full features missing)"; exit 1; }

echo -n "Checking qsv scripting engine (luau)... "
docker run --rm "${IMAGE_NAME}" qsv luau --help >/dev/null && echo "OK" || { echo "FAILED (full features missing)"; exit 1; }


# 3. Check Python namespace package imports
echo "Checking Python packages..."
PACKAGES=(
  "dartfx.utils"
  "dartfx.ddi"
  "dartfx.ckan"
  "dartfx.dataverse"
  "dartfx.nada"
  "dartfx.qsv"
  "dartfx.rdf"
  "dartfx.unf"
  "psycopg"
)

for pkg in "${PACKAGES[@]}"; do
  echo -n "  - Importing ${pkg}... "
  docker run --rm "${IMAGE_NAME}" python -c "import ${pkg}" >/dev/null 2>&1 && echo "OK" || { echo "FAILED"; exit 1; }
done

echo "=== All checks passed successfully! ==="
