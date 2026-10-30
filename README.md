# Pythio

_Current as of Build 119 (2026-10-29)._

A real-time healing roguelite: you are Pythio, a battlefield healer for hire, keeping a party
alive through endless rounds with WoW-style raid-frame healing and spells that combo through
their tags. Any death ends the run.

## Status
- **Live:** Build 119 (commit `f73b2ab`, Steam polish steps 1 and 2). Every merge to `master`
  deploys automatically; the build number shows in the bottom-right corner.
- **Current milestone:** [Phase G: Readability and feel](https://github.com/MarcialPimentel/pythio-godot/milestone/6)
  (sound waits on Marz's sound files). Next: [Phase H: Words, names and flair](https://github.com/MarcialPimentel/pythio-godot/milestone/9).
- What changed in each build: [CHANGELOG.md](CHANGELOG.md). The plan: [docs/roadmap.md](docs/roadmap.md).

## Play it
**https://marz.gg/games/pythio/** (desktop browser with WebGL 2; hard-refresh with Ctrl+F5 if
you see an old build number). How to playtest: [docs/playtest.md](docs/playtest.md).

## Run it locally
Godot **4.3** (GL Compatibility). From the repo root:

```bash
godot --headless --import            # first time only
godot                                # open the editor, then press F5 (main scene: scenes/Game.tscn)
tools/tests/run_all.sh path/to/godot # the automated tests CI runs before every deploy
```

## Docs
Every doc, what it's for and whether it's current: [docs/README.md](docs/README.md).
The design (pillars, rules, Decision Log) is in [docs/game-design.md](docs/game-design.md).
