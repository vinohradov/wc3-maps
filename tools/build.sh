#!/usr/bin/env bash
# Build: copy the original map, replace edited files, check JASS, install into Maps\Download
set -euo pipefail
source "$(dirname "$0")/env.sh"
if [ -x "$PJASS" ]; then
  "$PJASS" "$ROOT/tools/jass/common.j" "$ROOT/tools/jass/Blizzard.j" "$ROOT/src/map/war3map.j"
fi
mkdir -p "$ROOT/maps/build"
cp "$ORIGINAL" "$OUT"
for f in "${FILES[@]}"; do
  "$MPQ" add "$(w "$OUT")" "$(w "$ROOT/src/map/$(unix_path "$f")")" "$f" /c /auto
done
"$MPQ" compact "$(w "$OUT")" >/dev/null 2>&1 || true
ls -la "$OUT"
cp "$OUT" "$WC3/Maps/Download/" && echo "Installed to $WC3/Maps/Download/$OUT_NAME"
