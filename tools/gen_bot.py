"""Generate the bot data table and inject src/reforged/bot.j into war3map.j.

  uv run python tools/gen_bot.py
Writes the block between '//#BEGIN Reforged_Bot' and '//#END Reforged_Bot' (inserted after the
Reforged shop helpers on first run). Data: per-builder rosters, upgrades and shop summons, each with a
strength score = sqrt(HP * DPS) of the unit that actually fights (fighter copy via xv/ev arrays).
"""
import re
import runpy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
J = ROOT / "src" / "map" / "war3map.j"
BOT = ROOT / "src" / "reforged" / "bot.j"
sys.argv = sys.argv[:1]
g = runpy.run_path(str(ROOT / "tools" / "units.py"))
bal, wp, func = g["balance"], g["weapons"], g["func"]

BUILDERS = "u001 u000 u003 u002 u00C u00G u00H u00I u00J u00L u00O u00M u00K u00T u00P u00U u00Z".split()
SHOPS = ["h05C", "h9B0", "h0AZ", "h0B0"]  # shops with real stock (locked twins / h05D sell nothing)


def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return 0.0


script = J.read_text(encoding="latin-1")
fighter, xv = {}, None
for line in script.splitlines():
    m = re.fullmatch(r"set (xv|ev)\[K\]='(\w{4})'", line.strip())
    if m and m.group(1) == "xv":
        xv = m.group(2)
    elif m and xv:
        fighter[m.group(2)] = xv
        xv = None


def score(u):
    fu = fighter.get(u, u)
    b, w = bal.get(fu, {}), wp.get(fu, {})
    avg = f(w.get("dmgplus1")) + f(w.get("dice1")) * (f(w.get("sides1")) + 1) / 2
    dps = avg / (f(w.get("cool1")) or 1)
    return int((f(b.get("HP")) * dps) ** 0.5)


ATK = {"normal": 0, "pierce": 1, "siege": 2, "magic": 3, "chaos": 4}
DEF = {"small": 0, "medium": 1, "large": 2, "fort": 3, "normal": 4, "hero": 5, "divine": 6, "none": 7}
# the map's war3mapMisc DamageBonus table, percent, rows = ATK order, columns = DEF order
DAMAGE = [[90, 120, 90, 80, 80, 90, 100, 100], [130, 90, 80, 70, 70, 90, 100, 100],
          [90, 90, 90, 125, 125, 90, 100, 100], [110, 80, 120, 70, 70, 90, 100, 100], [100] * 8]


def atk(u):
    return ATK.get((wp.get(fighter.get(u, u), {}).get("atkType1") or "").lower(), 4)


def arm(u):
    return DEF.get((bal.get(fighter.get(u, u), {}).get("defType") or "").lower(), 7)


def rng(u):
    return int(f(wp.get(fighter.get(u, u), {}).get("rangeN1")))


def gold(u):
    return int(f(bal.get(u, {}).get("goldcost")))


lines = []
b_units, upgrades, seen = [], [], set()
for bi, b in enumerate(BUILDERS):
    lines.append(f"call SaveInteger(Reforged_HT,8,{bi},'{b}')")
    lines.append(f"call SaveInteger(Reforged_HT,9,{bi},{len(b_units)})")
    for u in [x for x in func.get(b, {}).get("Builds", "").split(",") if x]:
        if gold(u) <= 0:
            continue
        b_units.append((u, gold(u), score(u)))
        stack = [u]
        while stack:
            cur = stack.pop()
            for n in [x for x in func.get(cur, {}).get("Upgrade", "").split(",") if x]:
                if (cur, n) not in seen and gold(n) > 0:
                    seen.add((cur, n))
                    upgrades.append((cur, n, gold(n), max(0, score(n) - score(cur))))
                    stack.append(n)
    lines.append(f"call SaveInteger(Reforged_HT,10,{bi},{len(b_units) - 1})")
lines.append(f"call SaveInteger(Reforged_HT,21,0,{len(BUILDERS)})")
for i, (u, c, s) in enumerate(b_units):
    lines.append(f"call SaveInteger(Reforged_HT,11,{i},'{u}')")
    lines.append(f"call SaveInteger(Reforged_HT,12,{i},{c})")
    lines.append(f"call SaveInteger(Reforged_HT,13,{i},{s})")
    lines.append(f"call SaveInteger(Reforged_HT,26,{i},{rng(u)})")
    lines.append(f"call SaveInteger(Reforged_HT,33,{i},{atk(u)})")
    lines.append(f"call SaveInteger(Reforged_HT,34,{i},{arm(u)})")
    lines.append(f"call SaveInteger(Reforged_HT,38,'{u}',{arm(u) + 1})")
for i, (a, b, c, s) in enumerate(upgrades):
    lines.append(f"call SaveInteger(Reforged_HT,14,{i},'{a}')")
    lines.append(f"call SaveInteger(Reforged_HT,15,{i},'{b}')")
    lines.append(f"call SaveInteger(Reforged_HT,16,{i},{c})")
    lines.append(f"call SaveInteger(Reforged_HT,17,{i},{s})")
    lines.append(f"call SaveInteger(Reforged_HT,29,{i},{1 if rng(b) >= 200 else 0})")
    lines.append(f"call SaveInteger(Reforged_HT,35,{i},{atk(b)})")
    lines.append(f"call SaveInteger(Reforged_HT,36,{i},{arm(b)})")
    lines.append(f"call SaveInteger(Reforged_HT,38,'{b}',{arm(b) + 1})")
lines.append(f"call SaveInteger(Reforged_HT,21,1,{len(upgrades)})")
n = 0
for shop in SHOPS:
    for u in [x for x in func.get(shop, {}).get("Sellunits", "").split(",") if x]:
        if int(f(bal.get(u, {}).get("stockMax"))) <= 0:
            continue
        lines.append(f"call SaveInteger(Reforged_HT,18,{n},'{shop}')")
        lines.append(f"call SaveInteger(Reforged_HT,19,{n},'{u}')")
        lines.append(f"call SaveInteger(Reforged_HT,20,{n},{int(f(bal[u].get('lumbercost')))})")
        lines.append(f"call SaveInteger(Reforged_HT,39,{n},{atk(u)})")
        n += 1
lines.append(f"call SaveInteger(Reforged_HT,21,2,{n})")

for a, row in enumerate(DAMAGE):
    for d, pct in enumerate(row):
        lines.append(f"call SaveInteger(Reforged_HT,30,{a * 8 + d},{pct})")
waves = re.findall(r"set F\[K\]='(\w{4})'", script)[:30]
for lvl, u in enumerate(waves, 1):
    lines.append(f"call SaveInteger(Reforged_HT,31,{lvl},{atk(u)})")
    lines.append(f"call SaveInteger(Reforged_HT,32,{lvl},{arm(u)})")

# ---- Insane: proven "core" units (from the map owner's experience) and the value needed per level.
# (base unit, upgrade chain, upgrade_first): upgrade_first cores finish upgrades before building more
# (2 Elite Archers, 3 Veterans, 2 Frenzy Ghouls hold level 1); mass cores build the base unit
# (8 Ogres, 2 Grizzlies, 4-5 Raiders, 2 Outcasts hold level 1). All of them are ~400 gold for level 1.
CORES = [("h012", ["h013"], 0), ("h09W", ["h09M"], 1), ("h00M", ["h00T"], 1), ("h0CI", ["h0CK"], 1),
         ("h018", ["h019"], 0), ("h0BX", ["h0C0"], 0), ("h05V", ["h05W"], 0),
         # 1 Spawn of Dragon holds level 1; splash Dragon Aspects carry level 5
         ("h01A", ["h01B"], 1),
         # flag 2 = ranged carry: about half the gold into the carry, the other half into melee tanks
         ("h021", ["h022"], 2)]
for ci, (base, chain, first) in enumerate(CORES):
    lines.append(f"call SaveInteger(Reforged_HT,43,{ci},'{base}')")
    lines.append(f"call SaveInteger(Reforged_HT,44,{ci},{first})")
    for u in [base] + chain:
        lines.append(f"call SaveInteger(Reforged_HT,45,'{u}',{ci + 1})")
lines.append(f"call SaveInteger(Reforged_HT,21,5,{len(CORES)})")
# ---- Insane: aura supports (owner's rules). (base, final, how many to build, how many of them to upgrade,
# army value needed before buying, ranged_only). Slow auras: 2, placed 6 columns apart. Commander aura
# stacks: build 2, upgrade 1. Healing / Telescope / Adrenaline don't stack: 1 each, upgraded.
SUPPORTS = [("h0BJ", "h0BK", 2, 2, 1200, 0), ("h0C4", "h0C2", 1, 1, 1500, 0), ("h00P", "h00Z", 2, 1, 2500, 0),
            ("h0AH", "h0AJ", 1, 1, 2500, 1), ("h016", "h017", 1, 1, 4000, 0)]
for si, (base, final, count, ups, minval, ranged_only) in enumerate(SUPPORTS):
    for key, val in ((46, f"'{base}'"), (47, f"'{final}'"), (48, count), (49, ups), (50, minval), (52, ranged_only)):
        lines.append(f"call SaveInteger(Reforged_HT,{key},{si},{val})")
    lines.append(f"call SaveInteger(Reforged_HT,51,'{base}',{si + 1})")
    lines.append(f"call SaveInteger(Reforged_HT,51,'{final}',{si + 1})")
lines.append(f"call SaveInteger(Reforged_HT,21,6,{len(SUPPORTS)})")
# value target: 400 at level 1 (owner's data), growing with wave threat^0.8 (fits his level 2-3 counts);
# boss levels 10/20/30 are arena fights, so just +30% over the previous level. Bots adapt it to their leaks.
counts = [int(x) for x in re.search(r'set Jv=",([\d,]+)', script).group(1).split(",")[:30]]
threat = []
for u, c in zip(waves, counts):
    b, w = bal[u], wp[u]
    avg = f(w.get("dmgplus1")) + f(w.get("dice1")) * (f(w.get("sides1")) + 1) / 2
    threat.append(c * (f(b["HP"]) * avg / (f(w.get("cool1")) or 1)) ** 0.5)
target = []
for lvl in range(1, 31):
    t = 400 * (threat[lvl - 1] / threat[0]) ** 0.8
    if lvl in (10, 20, 30):
        t = target[-1] * 1.3
    if target:  # never below the previous level, and at most +40% per level (wave 14 is an outlier)
        t = min(max(t, target[-1]), target[-1] * 1.4)
    target.append(int(t))
    lines.append(f"call SaveInteger(Reforged_HT,41,{lvl},{target[-1]})")
print("insane value targets:", target)

# JASS limits the number of operations per function call, so split the data into chunks
chunks, out = [lines[i:i + 400] for i in range(0, len(lines), 400)], []
for i, c in enumerate(chunks):
    out.append(f"function Reforged_BotData{i} takes nothing returns nothing\n" + "\n".join(c) + "\nendfunction\n")
out.append("function Reforged_BotData takes nothing returns nothing\n" +
           "\n".join(f"call Reforged_BotData{i}()" for i in range(len(chunks))) + "\nendfunction\n")

block = "//#BEGIN Reforged_Bot (generated by tools/gen_bot.py from src/reforged/bot.j)\n" + \
        "".join(out) + BOT.read_text(encoding="utf-8").replace("\r\n", "\n") + \
        (BOT.parent / "debug.j").read_text(encoding="utf-8").replace("\r\n", "\n") + "//#END Reforged_Bot\n"
if "//#BEGIN Reforged_Bot" in script:
    script = re.sub(r"//#BEGIN Reforged_Bot.*?//#END Reforged_Bot\n", lambda _m: block, script, flags=re.S)
else:
    anchor = "function Reforged_UpdateShops takes nothing returns nothing\n"
    end = script.index("\nendfunction\n", script.index(anchor)) + len("\nendfunction\n")
    script = script[:end] + block + script[end:]
J.write_text(script, encoding="latin-1", newline="")
print(f"builders={len(BUILDERS)} units={len(b_units)} upgrades={len(upgrades)} summons={n} lines={len(lines)}")
