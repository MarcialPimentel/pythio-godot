# Automated checks (no screen needed)

Run from the repo root with Godot 4.3. Each script plays part of the game (picking the first card on any school/spell pick screen) and prints
`TEST:` lines; look for unexpected values and any `ERROR` / `SCRIPT ERROR`.

| Script | What it checks |
|---|---|
| `test_casting.gd` | click and hover+key casting, cast bar, mana costs, out-of-mana, round end cancels a cast |
| `test_fighters.gd` | armor roll mix, HP by armor, damage by armor, death ends the run, Play Again |
| `test_full_run.gd` | endless: round lengths, Baron every 5th round, mana top-up, rounds 1–12, death ends the run, Play Again |
| `test_bursts.gd` | bursts land after their warning for the right damage, shields absorb them, nothing lands between rounds |
| `test_debug_panel.gd` | F1 toggles the panel; jump to round, +mana, god mode, hit/heal, skip round; debug runs can't be posted; Play Again starts clean |
| `test_effects.gd` | every effect and status (heal, neighbours, most injured, heal-over-time, shields incl. heal-on-end, protection, death save, delayed heal, Overgrowth, Echo, Spirit Surge, mana), passive hooks, tag text |
| `test_picks.gd` | school pick, pick schedule, offer rules (no owned/duplicate spells, one other-school card), rank-ups replace in place, cap → rank-ups only → build complete once, the real school → round → pick → contracts flow |
| `test_combos.gd` | real casts of Renew → Overgrowth, Echo Healing → Heal, Shield → Spirit Surge; gold combo text, Pythio's quip, combo spells only offered once you own the tag they react to |
| `screenshots.gd` | saves real screenshots of start, contract choice, boss, game over |

```bash
godot --headless --script tools/tests/test_casting.gd
godot --headless --script tools/tests/test_fighters.gd
godot --headless --script tools/tests/test_bursts.gd
godot --headless --script tools/tests/test_effects.gd
godot --headless --script tools/tests/test_picks.gd
godot --headless --script tools/tests/test_combos.gd
godot --headless --script tools/tests/test_debug_panel.gd
timeout 180 godot --headless --script tools/tests/test_full_run.gd   # fast-forwarded; quits on its own after Play Again
# screenshots need a (virtual) display:
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script tools/tests/screenshots.gd -- /tmp/pythio
```
