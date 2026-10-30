# Pythio — Playtesting

_Current as of Build 119 (2026-10-29)._

## Play the current build
- **Link:** https://marz.gg/games/pythio/ in a desktop browser (needs WebGL 2).
- **Check the build:** the bottom-right corner shows `Build <number> · <commit>`. It should match
  the newest entry in [CHANGELOG.md](../CHANGELOG.md). If it's older, hard-refresh (Ctrl+F5).
- **Try a change before it merges:** each pull request has a downloadable web build under
  **Checks → Web build & deploy → Artifacts** (see [deploy.md](deploy.md)).
- Single player only; there's no multiplayer to test.

## Controls
| Action | Input |
|---|---|
| Cast a spell | Hover a fighter, press Q / W / E / R (or click a spell button, then a fighter) |
| Bandage | Space while hovering a fighter |
| Cleanse | F while hovering a fighter |
| Ready on Next party | Space or Enter |
| Choose a pick card | Click, or 1–3 (4 = Skip) |
| Pause menu (volume, reduce effects, restart, quit) | Escape |
| Debug panel (more mana, jump rounds, take any spell, god mode) | F1 — debug runs can't be posted to the leaderboard |

The full controls and screen layout are in [game-design.md](game-design.md) section 11.

## What to look for now
- **Steam polish (Build 119):** does the screen fit your window (try resizing, or a Steam Deck)?
  Is all text readable? Do the shake, combo lean and sparks feel good, or too much (try "Reduce
  screen shake and flashes" in the Escape menu)?
- **Phases E and F and the Code health fixes:** passives from the Baron's bounty, debuffs from
  round 6 and Cleanse on F. Is Ward (the Shield start) much harder than the others? The bot's
  first deaths averaged round 4.7 for Ward vs 6.4 overall.
- Anything that feels like a non-choice, an unreadable moment or a spell you never want to pick
  (check it against the pillars in [game-design.md](game-design.md) section 1).

## How to report feedback
Tell Claude in a session: what round you reached, which first spell you chose, what felt good or
bad, and the build number from the corner. For a bug, say what you did, what you expected and what
happened. Claude turns it into GitHub issues on the right milestone
(https://github.com/MarcialPimentel/pythio-godot/milestones).
