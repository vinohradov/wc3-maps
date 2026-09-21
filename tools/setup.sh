#!/usr/bin/env bash
# Download third-party tools into tools/bin and extract 1.26a common.j/Blizzard.j into tools/jass (for pjass)
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/tools/bin" "$ROOT/tools/jass"
cd "$ROOT/tools/bin"
[ -f mpqeditor/x64/MPQEditor.exe ] || { curl -sSL -o mpqeditor.zip http://www.zezula.net/download/mpqeditor_en.zip && unzip -o -q mpqeditor.zip -d mpqeditor; }
[ -f pjass.exe ] || curl -sSL -o pjass.exe https://github.com/lep/pjass/releases/download/release-2026-06-15/pjass.exe
# MPQEditor can't find these in War3Patch.mpq (no listfile), so read them with mpyq by exact name
cd "$ROOT/tools/jass"
uv run -q --with mpyq python - "$WC3/War3Patch.mpq" <<'PY'
import mpyq, sys
a = mpyq.MPQArchive(sys.argv[1], listfile=False)
for n in ("common.j", "Blizzard.j"):
    open(n, "wb").write(a.read_file("Scripts\\" + n))
PY
echo "Tools ready."
