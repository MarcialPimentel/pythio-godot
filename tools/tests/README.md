# Automated checks (no screen needed)

Run from the repo root with Godot 4.3. Each script plays part of the game and prints
`TEST:` lines; look for unexpected values and any `ERROR` / `SCRIPT ERROR`.

| Script | What it checks |
|---|---|
| `test_casting.gd` | click and hover+key casting, cast bar, mana costs, out-of-mana, round end cancels a cast |
| `test_fighters.gd` | armor roll mix, HP by armor, damage by armor, death ends the run, Play Again |
| `test_full_run.gd` | endless: round lengths, Baron every 5th round, mana top-up, rounds 1–12, death ends the run, Play Again |
| `test_debug_panel.gd` | F1 toggles the panel; jump to round, +mana, god mode, hit/heal, skip round; debug runs can't be posted; Play Again starts clean |
| `screenshots.gd` | saves real screenshots of start, contract choice, boss, game over |

```bash
godot --headless --script tools/tests/test_casting.gd
godot --headless --script tools/tests/test_fighters.gd
godot --headless --script tools/tests/test_debug_panel.gd
timeout 180 godot --headless --script tools/tests/test_full_run.gd   # fast-forwarded; quits on its own after Play Again
# screenshots need a (virtual) display:
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script tools/tests/screenshots.gd -- /tmp/pythio
```
