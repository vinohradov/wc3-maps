#!/usr/bin/env bash
# Build: copy the original map, replace edited files, check JASS, install into Maps\Download
set -euo pipefail
source "$(dirname "$0")/env.sh"
(cd "$ROOT" && uv run -q python tools/lint_shadow.py)
if [ -x "$PJASS" ]; then
  "$PJASS" "$ROOT/tools/jass/common.j" "$ROOT/tools/jass/Blizzard.j" "$ROOT/src/map/war3map.j"
fi
mkdir -p "$ROOT/maps/build"
cp "$ORIGINAL" "$OUT"
stage="$(mktemp -d)"
for f in "${FILES[@]}"; do
  src="$ROOT/src/map/$(unix_path "$f")"
  if [ "$f" = war3map.j ]; then
    # src keeps LF; the map ships with CR-only line endings, so restore those
    tr -d '\r' < "$src" | tr '\n' '\r' > "$stage/war3map.j"
    src="$stage/war3map.j"
  elif [ "$f" = war3map.wts ]; then
    # the game crashes on the map list if the strings file isn't CRLF (Git Bash sed -i strips CRs)
    tr -d '\r' < "$src" | sed 's/$/\r/' > "$stage/war3map.wts"
    src="$stage/war3map.wts"
  fi
  "$MPQ" add "$(w "$OUT")" "$(w "$src")" "$f" /c /auto
done
rm -rf "$stage"
"$MPQ" compact "$(w "$OUT")" >/dev/null 2>&1 || true
# name shown in the 1.26 map list comes from the HM3W header, not from war3map.wts
(cd "$ROOT" && uv run -q python tools/set_header.py "$OUT" "$LIST_NAME")
ls -la "$OUT"
# Install only on request (Program Files needs write permission): INSTALL=1 bash tools/build.sh
if [ "${INSTALL:-0}" = 1 ]; then
  cp "$OUT" "$WC3/Maps/Download/" && echo "Installed to $WC3/Maps/Download/$OUT_NAME"
fi
