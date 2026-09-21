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

## Tools
- `tools/units.py <name|id>` / `--tree <builder>` — unit lookup (cost, stats, upgrades)
- `tools/balance.py [N]` — rank buildable units by value per gold (uses fighter copies)
- `tools/slk_set.py <file> <id> <column> <value>` — change one SLK cell
- `tools/reforged_objects.py` — (re)generates all new objects (Legendary Barracks, summons, auras, Challenge); idempotent
- `tools/objmod.py <file.w3a>` — dump binary object-mod files
- `tools/gen_bot.py` — regenerates the bot data table and injects `src/reforged/bot.j` into war3map.j (run after changing units or bot.j)
- Script additions in `war3map.j` are prefixed `Reforged_`.

## Reforged changes (vs. original v3.9f)
- Name "Reforged"; default mode `-hpgmcb`; host pick auto-picks Prophet after 20 s
- Balance: Infernal burn 7 dps, Greymane large armor, Ogre Basher 45, Veteran 923 HP,
  Proton 25 / Adept +155, Peewee 20, Servant 35, Tuskarr 15; sell-exploit point values fixed
- Waves 6, 15, 18, 19, 21, 22, 23, 25, 26 stronger
- Summons blocked on levels 1/10/20/30 unless mode `-sa`
- Legendary Barracks from level 20: Pit Lord, Faceless One, Anub'arak, Nether Dragon, Eredar Warlock, Mannoroth
- Bots: lobby Computer slots (Easy/Normal/Insane) play like humans; games with bots send no win/loss stats
- Challenge (Town shop): Champion creep with 10x HP + aura, reward (wave+1)*15 + 10*streak
- Note: the map has an anti-cheat gold ledger `Br[]` — any gold given by script must be added to it

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
