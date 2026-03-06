#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/agillis/esphome-modular-lvgl-buttons.git"
REPO_DIR="esphome-modular-lvgl-buttons"
EXAMPLE_DIR="example_code"
PASS=0
FAIL=0
FAILED_FILES=()

# Clone the repo (fresh copy)
if [ -d "$REPO_DIR" ]; then
  echo "Removing existing $REPO_DIR..."
  rm -rf "$REPO_DIR"
fi
echo "Cloning $REPO_URL..."
git clone "$REPO_URL"

cd "$REPO_DIR"


# Check example_code directory exists
if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "ERROR: $EXAMPLE_DIR directory not found!"
  exit 1
fi

echo ""
echo "========================================="
echo "Testing config files from $EXAMPLE_DIR"
echo "========================================="
echo ""

for yaml_file in "$EXAMPLE_DIR"/*.yaml; do
  [ -f "$yaml_file" ] || continue
  basename=$(basename "$yaml_file")

  echo "--- Testing: $basename ---"

  # Copy to top level
  cp "$yaml_file" "$basename"

  # Run esphome config and capture output
  if output=$(esphome config "$basename" 2>&1); then
    echo "  PASS"
    ((PASS++))
  else
    echo "  FAIL"
    echo "$output" | sed 's/^/    /'
    ((FAIL++))
    FAILED_FILES+=("$basename")
  fi

  # Clean up the copied file
  rm -f "$basename"
  echo ""
done

echo "========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="
if [ ${#FAILED_FILES[@]} -gt 0 ]; then
  echo "Failed files:"
  for f in "${FAILED_FILES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
