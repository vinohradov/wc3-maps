"""Rank every buildable unit by raw combat value per gold vs. peers of similar total cost.
  uv run python tools/balance.py [N]    # top/bottom N (default 15)
value = sqrt(HP * DPS) / total gold, using the FIGHTER copy's stats (what actually fights).
Ignores abilities, armor/attack matchups and range — treat as a pointer, not a verdict.
"""
import runpy
import statistics
import sys
from pathlib import Path

sys.argv, N = sys.argv[:1], int(sys.argv[1]) if len(sys.argv) > 1 else 15
g = runpy.run_path(str(Path(__file__).with_name("units.py")))
bal, wp, func, name = g["balance"], g["weapons"], g["func"], g["name"]
ua = g["read_slk"]("UnitAbilities.slk")
astr = g["read_txt"]("CampaignAbilityStrings.txt")
BUILDERS = "u001 u000 u003 u002 u00C u00G u00H u00I u00J u00L u00O u00M u00K u00T u00E u00P u00U u00Z".split()


def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return 0.0


roster = {}  # build id -> total gold


def walk(u, paid):
    t = paid + f(bal.get(u, {}).get("goldcost"))
    roster.setdefault(u, t)
    for n in func.get(u, {}).get("Upgrade", "").split(","):
        if n:
            walk(n, t)


for b in BUILDERS:
    for u in func.get(b, {}).get("Builds", "").split(","):
        if u:
            walk(u, 0)
# exact build -> fighter mapping from the script: "set xv[K]='<fighter>'" / "set ev[K]='<build>'" at the same K
import re
fighter, xv = {}, None
for line in (Path(__file__).resolve().parent.parent / "src/map/war3map.j").read_text(encoding="latin-1").splitlines():
    m = re.fullmatch(r"set (xv|ev)\[K\]='(\w{4})'", line.strip())
    if m and m.group(1) == "xv":
        xv = m.group(2)
    elif m and xv:
        fighter[m.group(2)] = xv
        xv = None


def combat(u):
    fu = fighter.get(u, u)  # fighter copy if present
    b, w = bal.get(fu, {}), wp.get(fu, {})
    avg = f(w.get("dmgplus1")) + f(w.get("dice1")) * (f(w.get("sides1")) + 1) / 2
    dps = avg / (f(w.get("cool1")) or 1)
    abil = [astr.get(a, {}).get("Name", a) for a in (ua.get(fu, {}).get("abilList") or "").split(",")
            if a and a not in ("_", "A008")]
    return fu, f(b.get("HP")), dps, w.get("atkType1"), b.get("defType"), w.get("rangeN1"), abil


rows = []
for u, t in roster.items():
    if t <= 0:
        continue
    fu, hp, dps, at, dt, rng, abil = combat(u)
    rows.append(dict(id=u, fid=fu, name=name(u), cost=t, hp=hp, dps=dps, at=at, dt=dt, rng=rng, abil=abil,
                     val=(hp * dps) ** 0.5 / t))
for r in rows:
    peers = [p["val"] for p in rows if p is not r and 0.75 * r["cost"] <= p["cost"] <= 1.25 * r["cost"]]
    r["x"] = r["val"] / statistics.median(peers) if peers else 1
rows.sort(key=lambda r: -r["x"])


def pr(r):
    print(f"{r['x']:5.2f}x {r['id']} {r['name'][:20]:20} {r['cost']:5.0f}g hp={r['hp']:5.0f} dps={r['dps']:6.1f} "
          f"{r['at']}/{r['dt']} rng={r['rng']} {', '.join(r['abil'])}")


print(f"--- strongest {N} ---")
for r in rows[:N]:
    pr(r)
print(f"--- weakest {N} ---")
for r in rows[-N:]:
    pr(r)
