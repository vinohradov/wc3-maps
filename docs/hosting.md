# Hosting on iCCup (research, 2026-09-21 — verify before relying on it)

## Options
1. **iCCup host bot `/chost <code> <game name>`** — no port forwarding, but only for maps on iCCup's list
   (`/clist`; list thread https://iccup.com/community/thread/1650309.html). Our mod is not on it.
   Adding a map = request in the "Custom апдейт" forum section (thread named exactly like the map,
   link from an official site or epicwar.com); admins add maps in batches, mostly popular ones.
   Rules: https://iccup.com/community/thread/1405769.html
2. **Self-host from WC3 client** (Custom Game -> Create Game -> pick map) — needs TCP/UDP 6112 forwarded
   on the router + firewall allowed. Forum reports say self-hosted lobbies may be hard to see/join
   without an iCCup pro account — unconfirmed, test it.
3. **Third-party bot IrInA** (upload map at irinabot.ru, then `/j op pthb`, `!map <name>`, `!pub <name>`).
   One iCCup forum post says such bots were banned there — verify first.

## Map size / download
- Keep the map < 8 MB (1.26a limit). Ours: ~2.4 MB — OK.
- In-lobby download is slow and flaky on iCCup; offer a direct download link to players.
- Other players see the map by file name — bump `OUT_NAME` in tools/env.sh for each release so
  players don't clash with an older copy of the same name.

Sources: https://iccup.com/commands.html · https://iccup-launcher.ru/kak-sozdat-igru.php ·
https://iccup.com/community/thread/1644634.html · https://xgm.guru/p/irina/gamecreate

# Always-open lobby + player stats (research, 2026-09-21)

The always-open lobbies (e.g. LTDx20NG4.1.2bb) are most likely **IrInA autohost**, not iCCup bots (unconfirmed —
check the host-slot name in such a lobby and try `!stats` / `!checkme`).

Both LTDx20NG and our map use **W3MMD** (`InitGameCache("MMD.Dat")`), which bots read to record W/L/leaves.
The iCCup launcher's own lobby stats (`LobbyRaceFmt` in iccup.ini) only apply to iCCup's Custom Ladder maps.

## Options
1. **IrInA autohost (recommended)** — register at irinabot.ru (VK/Discord login), upload map (≤250 MB, 1.26 OK),
   create autohost on the website (`!autohost` removed). 299 RUB/month per slot. Reaches iCCup players; others
   can join via IrInA Connector. XGM monthly vote gives free autohost months.
   https://xgm.guru/p/irina/places · https://xgm.guru/p/irina/Otvety-na-chasto-zadavaemye-voprosy-m9s
2. **Own bot (Aura / GHost++) on a VPS** — Aura supports PvPGN (`pvpgn = true`), ghostone bots have run on iCCup,
   but no documented permission; iCCup bans for "advantage programs". Ask iCCup staff (Custom Discord) first.
   iCCup gateways (from bngates.dat): 137.74.4.81 main, 57.129.6.91 DE, 51.83.177.124 PL, 178.218.215.155 RU3.
3. **Official iCCup list** — request in "Custom апдейт" forum / Custom Discord; mainly popular maps; official list
   already has "Legion TD Mega v3.41c" (code LTD). Only Custom Ladder maps get stats.
   https://iccup.com/custom/ladder.html · https://iccup.com/community/thread/1650309.html
