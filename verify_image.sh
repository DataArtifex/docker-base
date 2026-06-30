#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="dartfx/docker-base:latest"

echo "=== Verifying Docker Image: ${IMAGE_NAME} ==="

# 1. Check system utilities
echo -n "Checking curl... "
docker run --rm "${IMAGE_NAME}" curl --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

echo -n "Checking jq... "
docker run --rm "${IMAGE_NAME}" jq --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

# 2. Check qsv binary installation
echo -n "Checking qsv... "
docker run --rm "${IMAGE_NAME}" qsv --version >/dev/null && echo "OK" || { echo "FAILED"; exit 1; }

# 3. Check Python namespace package imports
echo "Checking Python packages..."
PACKAGES=(
  "dartfx.utils"
  "dartfx.ddi"
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
