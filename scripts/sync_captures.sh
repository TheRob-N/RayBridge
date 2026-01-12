#!/bin/bash
set -euo pipefail

# ---- Config (override via environment variables) ----
ORBIC_BASE="${ORBIC_BASE:-http://192.168.1.1:8080}"
OUT_DIR="${OUT_DIR:-/var/www/html/rayhunter/captures}"
STATE_DIR="${STATE_DIR:-/opt/raybridge/state}"
SEEN_FILE="${SEEN_FILE:-$STATE_DIR/seen.txt}"
MANIFEST_JSON="${MANIFEST_JSON:-$STATE_DIR/manifest.json}"
# ----------------------------------------------------

mkdir -p "$OUT_DIR" "$STATE_DIR"
touch "$SEEN_FILE"

# Fetch manifest (lists recordings)
curl -fsS --max-time 15 "${ORBIC_BASE}/api/qmdl-manifest" -o "$MANIFEST_JSON"

# Extract recording names (robustly)
mapfile -t NAMES < <(
  jq -r '.. | objects | .name? // empty' "$MANIFEST_JSON" \
  | sed '/^$/d' \
  | sort -u
)

if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "No recording names found in manifest."
  exit 0
fi

downloaded=0
for name in "${NAMES[@]}"; do
  # Skip if already fetched
  if grep -Fxq "$name" "$SEEN_FILE"; then
    continue
  fi

  ts="$(date +%Y%m%d-%H%M%S)"
  tmp="${OUT_DIR}/${ts}__${name}.zip.part"
  final="${OUT_DIR}/${ts}__${name}.zip"

  echo "Downloading bundle for: $name"
  curl -fL --max-time 300 "${ORBIC_BASE}/api/zip/${name}" -o "$tmp"

  # Sanity check: non-empty
  if [ ! -s "$tmp" ]; then
    echo "Download empty for $name; leaving .part and not marking seen."
    continue
  fi

  mv "$tmp" "$final"
  echo "$name" >> "$SEEN_FILE"
  downloaded=$((downloaded+1))
done

echo "Done. New bundles downloaded: $downloaded"
