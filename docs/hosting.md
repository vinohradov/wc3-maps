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
