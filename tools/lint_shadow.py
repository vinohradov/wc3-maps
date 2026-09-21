"""Fail if any function parameter/local shadows a global name in war3map.j.

WC3 1.26 crashes (ACCESS_VIOLATION when the map is selected) on such shadowing, but pjass accepts it.
This map has short obfuscated globals (x, y, w, bi, ui ...), so it's easy to hit.
"""
import re
import sys
from pathlib import Path

s = (Path(__file__).resolve().parent.parent / "src" / "map" / "war3map.j").read_text(encoding="latin-1")
g = s[s.index("globals"):s.index("endglobals")]
globals_ = {m.group(1) for m in re.finditer(r"^(?:constant\s+)?\w+\s+(?:array\s+)?(\w+)", g, re.M)} - {"globals"}
bad = []
for fm in re.finditer(r"^function (\w+) takes (.*?) returns", s, re.M):
    body = s[fm.end():s.index("\nendfunction", fm.end())]
    params = [p.split()[-1] for p in fm.group(2).split(",") if p.strip() != "nothing"]
    for v in params + re.findall(r"^local\s+\w+\s+(?:array\s+)?(\w+)", body, re.M):
        if v in globals_:
            bad.append(f"{fm.group(1)}: '{v}' shadows a global")
if bad:
    print("Shadowed globals (crash on 1.26):\n  " + "\n  ".join(bad))
    sys.exit(1)
print(f"lint_shadow: ok ({len(globals_)} globals)")
