# wc3-maps

Modding **Legion TD Mega 3.5 x10 (v3.9f, by HuanAk)** for Warcraft III 1.26a and hosting it publicly on iCCup.

## Workflow (Git Bash)
```bash
bash tools/setup.sh     # once: MPQEditor + pjass into tools/bin, common.j/Blizzard.j into tools/jass
bash tools/extract.sh   # once: original map -> src/map/ (OVERWRITES local edits)
# edit files in src/map/
bash tools/build.sh     # pjass check -> maps/build/<name>.w3x -> copy into Warcraft III\Maps\Download
```
Build = copy of the original map with our edited files swapped in, so unnamed imported
models/textures (113 `File000xxxxx` entries) are preserved untouched.

## What the map looks like inside
The map is **protected/optimized**: no WE trigger files (`.wtg/.wct`), object data merged into SLKs,
imported file names stripped, script identifiers obfuscated. World Editor won't open it — edit text directly:
- `src/map/war3map.j` — the whole game logic (JASS, ~15k lines, obfuscated names). Original is CR-only; extract.sh converts to CRLF.
- `src/map/war3map.wts` — strings (`TRIGSTR_n`): map name (1277), description, tooltips, messages.
- `src/map/Units/*.slk` — object data tables: UnitBalance (HP, cost, armor), UnitWeapons (damage, cooldown, range), AbilityData, ItemData, UpgradeData.
- `src/map/Units/*.txt` — names, tooltips, icons, button positions.

## Environment
- Warcraft III 1.26a: `C:\Program Files\Warcraft III` — `Maps\Download` needs write permission for build.sh to install.
- iCCup launcher: `C:\Program Files (x86)\ICCup\Launcher`
- Hosting notes: `docs/hosting.md`
