#!/usr/bin/env bash
# Extract editable text files from the original map into src/map/ (overwrites local edits!)
set -euo pipefail
source "$(dirname "$0")/env.sh"
tmp="$(mktemp -d)"
"$MPQ" extract "$(w "$ORIGINAL")" "*" "$(w "$tmp")"
for f in "${FILES[@]}"; do
  rel="$(unix_path "$f")"
  mkdir -p "$ROOT/src/map/$(dirname "$rel")"
  cp "$tmp/$(basename "$rel")" "$ROOT/src/map/$rel"  # MPQEditor extracts flat
done
# war3map.j ships with CR-only line endings; convert to CRLF so it is readable/diffable
tr '\r' '\n' < "$ROOT/src/map/war3map.j" | sed 's/$/\r/' > "$tmp/j"
mv "$tmp/j" "$ROOT/src/map/war3map.j"
rm -rf "$tmp"
echo "Extracted ${#FILES[@]} files into src/map/"
