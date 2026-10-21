# Pythio — notes for Claude

## What the game is
You are a battlefield healer under extreme pressure. Real-time triage / plate-spinning:
several wounded fighters take continuous damage while a round timer ticks down, and you
keep every one of them alive with heals, shields and HoTs, a limited mana pool, and
reactions to telegraphed burst hits. Any death ends the run. Score = rounds survived;
the game is leaderboard-oriented and replayable. Ported from the web version at
https://marz.gg/games/pythio/.

**Loop (endless):** pick a specialization (Mending / Bloom / Ward) → choose a contract →
round runs (damage, bursts, mana regen) → survive the timer to advance → … forever, until a
fighter dies. The Crimson Baron returns every 5th round. Every 5 rounds you pick a new spell
(capped); later, a keystone every 10 rounds (capped). Score = how far you got.

## Current direction (owner's decisions — these win over docs/design.md)
Decided 2026-10-21; full reasoning in `docs/design-direction.md`.
- **The pitch:** World of Warcraft–style healing (raid frames, high-APM plate spinning,
  mana as the long game, reading incoming damage) combined with the **spell synergies and
  build-crafting of a roguelite**. Each run should play differently because of your choices.
- **Endless rounds.** The 5-round run was a pilot. Rounds stay under 30s.
- **Spell synergies are a core feature.** They work through **plain-language tags**
  (Balatro-style): spell text names tags like **Heal-over-Time**, and the same tags decide
  what interacts. No fixed spell pairs. When choosing between work items, favor the ones
  that make combos and synergies matter.
- **Builds:** a specialization at the start, then a new spell every 5 rounds (1 of 3,
  favoring your school, one off-school card), capped so the build reaches a "complete"
  point. Duplicate spells are ranks of one spell (Heal I/II/III); rank-ups are pick options.
- **Balance rule:** fast, efficient, big — pick two.
- **Parked:** duo spells, rerolls, skill tree / meta-progression, pet and positional spells.
- **What to work on next:** follow `docs/roadmap.md` (phases, one bullet ≈ one PR, each
  bullet is a GitHub issue). Spell ideas and baseline numbers: `docs/spells.md`.
- The original web game's design document is in `docs/design.md`. Use it for intent and
  ideas only.

**Design pillars** — check every change against these:
1. Triage pressure — you can never fully keep up; you must prioritize.
2. Meaningful choices — which spell, which target, when to combo, when to save mana.
3. Escalating chaos — rounds get harder and more chaotic.
4. Readable feedback — health bars, telegraphs, mana costs and spell responses stay
   clear even when things are intense.

**Tone & look:** darkly humorous noir; dry, understated quips from Pythio. Dark,
high-contrast UI. Accent colors carry meaning: emerald green = heals, electric blue =
shields, golden yellow = combos / powerful effects, blood red = danger / bursts.

**Combos:** complementary spells on the same target within a short window grant bonuses
(stronger heals, longer durations, mana refunds).

## Tech
- Godot **4.3**, GDScript, GL Compatibility renderer.
- Main scene: `scenes/Game.tscn` (script `scenes/game.gd`).
- Global systems are autoloads (see `project.godot`): GameManager, SpellSystem,
  TargetSystem, ContractGenerator, DifficultySystem, EventBus, PartyChoicePanel.
- Data lives in Resources: spells in `resources/spells/*.tres`, contracts and units in
  `data/`.

## Folder layout
- `autoload/systems/` — game-wide logic (rounds, spells, targets, difficulty, contracts)
- `autoload/events/EventBus.gd` — shared signals; systems talk through these
- `components/` — reusable node components (HealthComponent)
- `entities/` — the party member scene (Target)
- `scenes/`, `ui/` — main game scene and panels
- `data/`, `resources/` — data definitions and .tres files

## How to check a change
The project owner is not a programmer and tests by playing. Every change must leave the
game launching and playable. Before opening a PR:
1. `godot --headless --import` then `godot --headless --quit-after 300` from the repo root
   and confirm there are no new `ERROR` / `SCRIPT ERROR` lines.
2. In the PR description, write **plain-language test steps** ("Start a run, pick the left
   contract, cast Flash Heal on the first fighter — their health bar should rise").

## How we work (owner ↔ Claude)
- Claude opens one PR per change with plain-language test steps. When the change is a roadmap
  bullet, the PR description says "Closes #N" for that bullet's GitHub issue. Every PR gets a CI check
  (smoke test + web build, downloadable under the PR's Checks → Artifacts).
- The owner approves in chat by saying **"merge #N"**; Claude merges only the PR named.
  Merging to `master` deploys to https://marz.gg/games/pythio/ automatically.
- Start a new session by reading `docs/roadmap.md` → "Where we are". Keep that section
  current at the end of each batch of work.
- Testing without a screen: `godot --headless --script <test>.gd` drives the game; real
  screenshots via `xvfb-run godot --rendering-driver opengl3 --script <shot>.gd`.

## Working rules
- One feature or fix per pull request, on its own branch. Never push to `main`.
- Keep file names' capitalization consistent with how they're referenced (the game must
  run on Windows, Mac and Linux).
- Prefer EventBus signals over systems calling each other directly.
- Tunable numbers (damage, mana, rewards) belong in DifficultySystem/ContractGenerator
  exports or .tres data, not hard-coded in logic.
- Don't commit Godot `*.tmp` files or the `.godot/` folder.
- Don't change art direction, add new mechanics, or rename spells without the owner's OK.
