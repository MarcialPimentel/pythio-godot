# Pythio — Changelog

_Current as of Build 119 (2026-10-29). Newest first. A build number is the run number of the
"Web build & deploy" workflow that put it live; it shows in the game's bottom-right corner.
Builds are grouped by batch of work, so some numbers in between are skipped._

## Build 119 — 2026-10-29
- The game fills any screen shape (Steam Deck, ultrawide): no more black bars. ([#106](https://github.com/MarcialPimentel/pythio-godot/pull/106))
- No text smaller than 18 px; the bottom-right portrait is gone; pick and Next party screens no longer show an old title behind the new one. ([#106](https://github.com/MarcialPimentel/pythio-godot/pull/106))
- Screen feel: shake on big hits and deaths, a lean on combos, sparks, ground shadows, a hit flash and a dark veil when someone dies. "Reduce screen shake and flashes" is in the Escape menu. ([#106](https://github.com/MarcialPimentel/pythio-godot/pull/106))

## Build 116 — 2026-10-28 (Code health)
- Bug fixes: recasting a shield refreshes it, passive shields follow the battlefield rules, cooldowns stop while paused, heals-over-time keep their last tick, quitting right after a pick is safe. ([#97](https://github.com/MarcialPimentel/pythio-godot/pull/97))
- Leaderboard is harder to cheat and can't be wiped (one-time run tickets, safe saves with a backup); the current board is kept. ([#101](https://github.com/MarcialPimentel/pythio-godot/pull/101), [#104](https://github.com/MarcialPimentel/pythio-godot/pull/104), [#98](https://github.com/MarcialPimentel/pythio-godot/pull/98))
- A new build now shows up at once, without waiting for the host's cache. ([#100](https://github.com/MarcialPimentel/pythio-godot/pull/100))
- Behind the scenes: automated tests run before every deploy, round rules moved into one place, the screen script split up. ([#96](https://github.com/MarcialPimentel/pythio-godot/pull/96), [#99](https://github.com/MarcialPimentel/pythio-godot/pull/99), [#102](https://github.com/MarcialPimentel/pythio-godot/pull/102), [#103](https://github.com/MarcialPimentel/pythio-godot/pull/103))

## Build 95 — 2026-10-27
- Mana is icy cyan (bar, orb and costs); gold now only means combos. ([#89](https://github.com/MarcialPimentel/pythio-godot/pull/89))
- Sound system: volume and mute in the Escape menu; sounds arrive as Marz makes them (none yet). ([#90](https://github.com/MarcialPimentel/pythio-godot/pull/90))
- Art list with prompts, tag icons and one icon per spell. ([#88](https://github.com/MarcialPimentel/pythio-godot/pull/88))

## Build 88 — 2026-10-25 (Phase F)
- From round 6 fighters get debuffs: Poison, Bleed, Hex and Dread, with warnings above them. ([#87](https://github.com/MarcialPimentel/pythio-godot/pull/87))
- Cleanse on F (2 charges) for every run; bandages stop Bleed. ([#87](https://github.com/MarcialPimentel/pythio-godot/pull/87))

## Build 86 — 2026-10-25 (Phase E)
- Spell picks offer only spells; each Crimson Baron pays a passive ("The Baron's bounty"); six new passives. ([#86](https://github.com/MarcialPimentel/pythio-godot/pull/86))
- Every heal-over-time on a fighter shows; the timer flashes in the last 5 seconds. ([#85](https://github.com/MarcialPimentel/pythio-godot/pull/85))

## Build 82 — 2026-10-24
- **Choose your spell** to start (no schools on screen), one-sentence cards, cast time up front. ([#80](https://github.com/MarcialPimentel/pythio-godot/pull/80))
- "Job finished" screen between rounds so stray clicks can't skip ahead. ([#81](https://github.com/MarcialPimentel/pythio-godot/pull/81))
- Pythio on the title screen; a first-time practice round teaching Heal, Renew and Shield. ([#82](https://github.com/MarcialPimentel/pythio-godot/pull/82), [#83](https://github.com/MarcialPimentel/pythio-godot/pull/83), [#84](https://github.com/MarcialPimentel/pythio-godot/pull/84))
- High-res art: Pythio (idle, casting, low mana, hurt), the four fighters and the Crimson Baron, with fallen poses. ([#74](https://github.com/MarcialPimentel/pythio-godot/pull/74), [#76](https://github.com/MarcialPimentel/pythio-godot/pull/76), [#78](https://github.com/MarcialPimentel/pythio-godot/pull/78))
- Phase D kept as built; the Protection tag is now **Mitigation**. ([#79](https://github.com/MarcialPimentel/pythio-godot/pull/79))

## Build 54 — 2026-10-22 (Phase D)
- Picks every other round, 4 spell keys (Q–R), swap / upgrade / skip when the bar is full, offers lean toward your tags. ([#73](https://github.com/MarcialPimentel/pythio-godot/pull/73))
- Spell batch 2: nine new spells and passives. ([#73](https://github.com/MarcialPimentel/pythio-godot/pull/73))
- Escape menu (pause, restart, quit); "Add a passive" wording on the pick screen. ([#60](https://github.com/MarcialPimentel/pythio-godot/pull/60), [#59](https://github.com/MarcialPimentel/pythio-godot/pull/59))

## Build 42 — 2026-10-22 (Phase C)
- Fairer difficulty curve, passive tray, one Next party screen, combo-ready glow, bandages (Space). ([#57](https://github.com/MarcialPimentel/pythio-godot/pull/57))
- Battlefield rules with mirrored passives; effective healing, run summary and a new leaderboard; the Crimson Baron fight. ([#57](https://github.com/MarcialPimentel/pythio-godot/pull/57), [#58](https://github.com/MarcialPimentel/pythio-godot/pull/58))

## Build 33 — 2026-10-21 (Phase B)
- Pick a school, spell picks with rank-ups, 25 spells, tag-based combos with a gold flash. ([#48](https://github.com/MarcialPimentel/pythio-godot/pull/48))

## Build 30 — 2026-10-21 (Phase A)
- Endless rounds with the Crimson Baron every 5th round; bursts land after their warning; F1 debug panel. ([#43](https://github.com/MarcialPimentel/pythio-godot/pull/43), [#45](https://github.com/MarcialPimentel/pythio-godot/pull/45), [#46](https://github.com/MarcialPimentel/pythio-godot/pull/46))

## Build 18 — 2026-10-21
- The game is playable on the web at marz.gg, with an online leaderboard and a build number in the corner. ([#13](https://github.com/MarcialPimentel/pythio-godot/pull/13), [#14](https://github.com/MarcialPimentel/pythio-godot/pull/14), [#15](https://github.com/MarcialPimentel/pythio-godot/pull/15), [#16](https://github.com/MarcialPimentel/pythio-godot/pull/16), [#18](https://github.com/MarcialPimentel/pythio-godot/pull/18))

## Before the web build — 2026-10-12 to 2026-10-15
- The Godot version launches, rounds flow, spells cast with hover + Q/W/E, fighters can die, noir graphics with stand-in art. ([#6](https://github.com/MarcialPimentel/pythio-godot/pull/6), [#8](https://github.com/MarcialPimentel/pythio-godot/pull/8), [#9](https://github.com/MarcialPimentel/pythio-godot/pull/9), [#10](https://github.com/MarcialPimentel/pythio-godot/pull/10), [#11](https://github.com/MarcialPimentel/pythio-godot/pull/11), [#12](https://github.com/MarcialPimentel/pythio-godot/pull/12))
