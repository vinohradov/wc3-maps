"""Look up units in src/map object data.

  uv run python tools/units.py <name-or-id> [...]   # e.g. peewee  wisp  u00T
  uv run python tools/units.py --tree <builder-id>  # builder roster with upgrade chains, e.g. u00T (Prophet)
Shows id, name, cost, stats, what it upgrades into / builds, and who can build or upgrade into it.
"""
import re
import sys
from pathlib import Path

UNITS = Path(__file__).resolve().parent.parent / "src" / "map" / "Units"


def read_slk(name):
    """SLK -> {id: {column: value}} (first column is the id)."""
    cells, y = {}, None
    for line in (UNITS / name).read_text(encoding="latin-1").splitlines():
        if not line.startswith("C;"):
            continue
        m = re.search(r";Y(\d+)", line)
        if m:
            y = int(m.group(1))
        x = re.search(r";X(\d+)", line)
        k = re.search(r";K(.*)$", line)
        if x and k:
            cells.setdefault(y, {})[int(x.group(1))] = k.group(1).strip('"')
    header = cells.pop(1)
    return {row[1]: {header[c]: v for c, v in row.items() if c in header} for row in cells.values() if 1 in row}


def read_txt(name):
    """INI-style txt -> {id: {key: value}}."""
    out, cur = {}, None
    for line in (UNITS / name).read_text(encoding="utf-8-sig", errors="replace").splitlines():
        m = re.match(r"\[(\w{4})\]", line)
        if m:
            cur = out.setdefault(m.group(1), {})
        elif cur is not None and "=" in line:
            k, v = line.split("=", 1)
            cur[k] = v
    return out


balance = read_slk("UnitBalance.slk")
weapons = read_slk("UnitWeapons.slk")
func = read_txt("CampaignUnitFunc.txt")
if (UNITS / "CampaignUnitStrings.txt").exists():  # Reforged-only sections live here
    func.update(read_txt("CampaignUnitStrings.txt"))


def name(uid):
    return re.sub(r"\|c\w{8}|\|r", "", func.get(uid, {}).get("Name", "?"))


def refs(uid):
    """Units that list uid in their Upgrade= or Builds=."""
    return [(o, k) for o, d in func.items() for k in ("Upgrade", "Builds") if uid in d.get(k, "").split(",")]


def show(uid):
    b, w, f = balance.get(uid, {}), weapons.get(uid, {}), func.get(uid, {})
    print(f"[{uid}] {name(uid)}")
    print(f"  gold={b.get('goldcost', '-')} lumber={b.get('lumbercost', '-')} food={b.get('fused', '-')} "
          f"hp={b.get('HP', '-')} armor={b.get('def', '-')} ({b.get('defType', '-')}) bldtm={b.get('bldtm', '-')}")
    if w.get("dmgplus1"):
        print(f"  dmg={w.get('dmgplus1')}+{w.get('dice1')}d{w.get('sides1')} cd={w.get('cool1')} "
              f"range={w.get('rangeN1')} atk={w.get('atkType1')}")
    for k in ("Upgrade", "Builds"):
        if f.get(k):
            print(f"  {k}: " + ", ".join(f"{i} {name(i)}" for i in f[k].split(",") if i))
    for o, k in refs(uid):
        print(f"  <- {k} of {o} {name(o)}")


def tree(uid, depth=0):
    b = balance.get(uid, {})
    print("  " * depth + f"{uid} {name(uid)}  gold={b.get('goldcost', '-')} lumber={b.get('lumbercost', '-')} "
          f"hp={b.get('HP', '-')}")
    for n in func.get(uid, {}).get("Upgrade", "").split(","):
        if n:
            tree(n, depth + 1)


if sys.argv[1:2] == ["--tree"]:
    for u in func[sys.argv[2]].get("Builds", "").split(","):
        if u:
            tree(u)
    sys.exit()

for q in sys.argv[1:]:
    ids = [q] if q in func else [i for i in func if q.lower() in name(i).lower()]
    for i in ids:
        show(i)
