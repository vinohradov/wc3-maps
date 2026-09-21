# Lessons learned (read before touching the build or the script)

## The big crash (2026-09-21): ACCESS_VIOLATION at Game.dll 6F46005B on map select / load
**Cause (confirmed by automated in-game tests):** the original `war3map.j` uses CR-only line endings. WC3 1.26
ends a `//` comment only at LF, so with CR-only endings the first comment swallows the rest of the script and the
game crashes while compiling it (map select in the list, or `-loadfile`).
**Fix:** `tools/build.sh` strips comment lines and writes the script with CRLF. Comments in `src/` are fine.
Evidence: S1 (no comments) OK, S2 (first commit with `//`) crash; current script as CRLF / without comments OK.

Theories that were WRONG (don't repeat): map name too long; too many globals (the hashtable refactor was not
needed, but is harmless and kept); 512 KB limit of `CampaignUnitFunc.txt` (the split into
`CampaignUnitStrings.txt` / `CampaignAbilityFunc.txt` was not needed, harmless, kept); local/global name
shadowing (unverified; `tools/lint_shadow.py` kept as cheap insurance).
Unreliable user reports misled the bisection once ("S6 works" was wrong) - prefer the automated harness.

## Automated in-game load test (use it after every script change!)
`tools/wc3batch.ps1 -Folder <dir with zz_*.w3x> -Out <results.txt> -Seconds 45` - must run ELEVATED
(`Start-Process powershell -Verb RunAs ...`), starts `war3.exe -window -loadfile <map>`, detects new
`*Crash.txt`, kills war3. Results: OK / CRASH / EXITED (EXITED or an empty results file = run was interrupted,
e.g. the user closed windows - ask the user not to touch windows and retry).
Crash reports: elevated war3 -> `C:\Program Files\Warcraft III\Errors`; normal war3 ->
`%LOCALAPPDATA%\VirtualStore\Program Files\Warcraft III\Errors`.
`-loadfile` only proves the map compiles and starts loading - gameplay still needs a human test.

## Shell pitfalls on this machine (Git Bash on Windows)
- `sed -i` silently strips CR -> never use it on CRLF files (`war3map.wts`, SLKs). Use Python with
  `newline=''` / bytes, or the Edit tool.
- Bash heredocs (even quoted `<<'EOF'`) collapse `\\` to `\` and can turn `\r`/`\n` into real control chars.
  Never generate code containing backslashes through a heredoc: use the Write/Edit tools instead.
  JASS strings need `\\` in model paths - verify with pjass ("Invalid escape character sequence").
- `C:\Program Files` is not writable: install maps via an elevated `Copy-Item` (UAC prompt).
- MPQEditor CLI: `extract` is always flat; can't read War3Patch.mpq (use Python `mpyq` by exact file name);
  LTDx20NG map's MPQ also only opens with mpyq (`Scripts\war3map.j`).

## Map internals worth knowing
- 1.26 map list shows the HM3W header name (tools/set_header.py), not war3map.wts.
- Armor display names: internal `large` = "Heavy", `normal` = "Fortified", `small` = "Light".
- Anti-cheat gold ledger `Br[pid+1]`: any script-given gold must be added to it. Same-round sell refunds 100% of
  the unit's point value (`UnitData.slk` `points`) -> points must equal total gold paid.
- Summon cost is always level*20 lumber; income = points. Build/fighter unit pairs: `ev[K]`/`xv[K]` arrays.
- Shops are player-owned; stock 0 twins lock sending (Reforged_UpdateShops).
- Full mechanics map for bots (player init, build areas, economy, W3MMD): see git history of this file's
  sibling notes and `src/reforged/bot.j` header; key globals: `L` level, `Vv` wave running, `lr` arena,
  `N[]` builder, `Vr[]` adv. barracks, `Bo[]` army value, `Pe[]` income, `Qx[]` wisps, `co[]` leaks, `ox`/`xx` forces.
