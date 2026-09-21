"""Set one cell in an SLK table, keeping everything else byte-identical.
  uv run python tools/slk_set.py <file.slk> <object-id> <column> <value>
  e.g. uv run python tools/slk_set.py AbilityData.slk A11T DataA1 7
Numbers are written bare, anything else quoted.
"""
import re
import sys
from pathlib import Path

UNITS = Path(__file__).resolve().parent.parent / "src" / "map" / "Units"

name, oid, column, value = sys.argv[1:5]
path = UNITS / name
lines = path.read_bytes().decode("latin-1").split("\r\n" if b"\r\n" in path.read_bytes() else "\n")
eol = "\r\n" if b"\r\n" in path.read_bytes() else "\n"

# pass 1: locate header column and object row
cells, y = [], None  # (line_index, y, x, k)
for i, line in enumerate(lines):
    if not line.startswith("C;"):
        continue
    m = re.search(r";Y(\d+)", line)
    if m:
        y = int(m.group(1))
    x, k = re.search(r";X(\d+)", line), re.search(r";K(.*)$", line)
    if x:
        cells.append((i, y, int(x.group(1)), k.group(1) if k else None))
col = next((x for _, cy, x, k in cells if cy == 1 and k and k.strip('"') == column), None)
row = next((cy for _, cy, x, k in cells if x == 1 and k and k.strip('"') == oid), None)
if col is None or row is None:
    sys.exit(f"not found: column={column} -> {col}, id={oid} -> {row}")

val = value if re.fullmatch(r"-?\d+(\.\d+)?", value) else f'"{value}"'
hit = [c for c in cells if c[1] == row and c[2] == col]
if hit:
    i, _, _, old = hit[0]
    lines[i] = re.sub(r";K.*$", ";K" + val, lines[i])
    print(f"{name} {oid}.{column}: {old} -> {val}")
else:
    last = max(i for i, cy, _, _ in cells if cy == row)
    lines.insert(last + 1, f"C;X{col};K{val}")
    print(f"{name} {oid}.{column}: (empty) -> {val}")
path.write_bytes(eol.join(lines).encode("latin-1"))
