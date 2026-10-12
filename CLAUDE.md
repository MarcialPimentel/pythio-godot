# Pythio — notes for Claude

## What the game is
You are a battlefield healer under extreme pressure. Real-time triage / plate-spinning:
several wounded fighters take continuous damage while a round timer ticks down, and you
keep every one of them alive with heals, shields and HoTs, a limited mana pool, and
reactions to telegraphed burst hits. Any death ends the run. Score = rounds survived;
the game is leaderboard-oriented and replayable. Ported from the web version at
https://marz.gg/games/pythio/.

**Loop:** choose a contract (procedural party with armor types, HP, threat, reward, risk)
→ round runs (damage, bursts, mana regen) → survive the timer to advance → harder
contracts → final boss contract (round 5, "The Crimson Baron"). Between rounds you draft
new spells into your spellbook.

## Current direction (owner's decisions — these win over docs/design.md)
- **The pitch:** World of Warcraft–style healing (raid frames, cast times, mana as the
  long game, reading incoming damage) combined with the **spell synergies and build-crafting
  of a roguelite**. Each run should play differently because of the choices you make.
- **Spell synergies are a core feature, not a side system.** They were meant to be more
  prominent than the current code shows. When choosing between work items, favor the ones
  that make combos and synergies matter.
- **The spellbook is the build:** start by drafting **1 of 3** spells; after each round,
  draft 1 of 3 more into your spellbook (5 spells by the boss). Synergies come from
  mixing and matching drafted spells into cool combinations. There is no separate upgrade
  system; everything you pick is a spell.
- **MVP scope = a 5-round run** that represents the full game loop (contract choice →
  round → … → round-5 boss). Endless rounds, 27 spells and a talent tree every 5 rounds
  (from the original web design) are post-MVP.
- **What to work on next:** follow `docs/roadmap.md` (phases, one bullet ≈ one PR).
  Spell ideas and baseline numbers: `docs/spells.md`.
- The original web game's design document is in `docs/design.md`. Use it for intent, spell
  and synergy ideas, and reference numbers.

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

## Working rules
- One feature or fix per pull request, on its own branch. Never push to `main`.
- Keep file names' capitalization consistent with how they're referenced (the game must
  run on Windows, Mac and Linux).
- Prefer EventBus signals over systems calling each other directly.
- Tunable numbers (damage, mana, rewards) belong in DifficultySystem/ContractGenerator
  exports or .tres data, not hard-coded in logic.
- Don't commit Godot `*.tmp` files or the `.godot/` folder.
- Don't change art direction, add new mechanics, or rename spells without the owner's OK.
