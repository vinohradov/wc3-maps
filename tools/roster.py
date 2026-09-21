"""Print a builder's roster with models and ability descriptions (to identify units by nickname).
  uv run python tools/roster.py <builderId> [regex]     e.g. u00T "ghoul|murloc"
"""
import re
import runpy
import sys
from pathlib import Path

args = sys.argv[1:]
sys.argv = sys.argv[:1]
g = runpy.run_path(str(Path(__file__).with_name("units.py")))
bal, func, name = g["balance"], g["func"], g["name"]
ui, ua = g["read_slk"]("unitUI.slk"), g["read_slk"]("UnitAbilities.slk")
astr = g["read_txt"]("CampaignAbilityStrings.txt")
pattern = re.compile(args[1], re.I) if len(args) > 1 else None


def model(u):
    return (ui.get(u, {}).get("file") or "").replace("/", "\\").split("\\")[-1].replace(".mdl", "")


def abilities(u):
    out = []
    for a in (ua.get(u, {}).get("abilList") or "").split(","):
        if a and a not in ("_", "A008"):
            t = astr.get(a, {})
            tip = re.sub(r"\|c\w{8}|\|r|\|n", " ", t.get("Ubertip", ""))[:80]
            out.append(f"{t.get('Name', a)}: {tip}")
    return out


def lines(u, depth=0):
    if u not in bal or depth > 3:
        return []
    out = ["  " * depth + f"{u} {name(u)} {bal[u].get('goldcost')}g model={model(u)} {abilities(u)}"]
    for n in func.get(u, {}).get("Upgrade", "").split(","):
        if n:
            out += lines(n, depth + 1)
    return out


for u in func[args[0]]["Builds"].split(","):
    if u:
        text = "\n".join(lines(u))
        if not pattern or pattern.search(text):
            print(text)
