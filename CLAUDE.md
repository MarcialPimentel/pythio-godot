# Pythio — notes for Claude

## The game and its design: read `docs/game-design.md` first
Pythio is real-time, high-APM "plate spinning" healing in the style of WoW raid frames,
combined with roguelite build-crafting through tag-based spell synergies. Endless rounds;
any death ends the run.

- **`docs/game-design.md` is the single source of truth for what the game is.** Read it
  before making any design decision, and check every change against its **pillars**
  (triage pressure, meaningful choices, escalating chaos, readable feedback). It wins over
  every other design doc. Items marked **[Decided]** are the owner's; **[Proposed]** are
  Claude's suggestions awaiting his call. When you change how the game works, update the
  matching section (and its tunables table) in the same PR and add a changelog line.
- **`docs/roadmap.md` is the work plan:** what to build next, one bullet ≈ one PR ≈ one
  GitHub issue. Favour work that makes combos and synergies matter.
- `docs/spells.md` is the spell catalog with real numbers. `docs/design-direction.md` is
  the frozen record of the 2026-10-21 design review (the *why*). `docs/design.md` is the
  original web game's doc: ideas only.
- Act as a game design veteran: push back when something weakens a pillar and suggest a
  better option. The owner makes the final call.

## Tech
- Godot **4.3**, GDScript, GL Compatibility renderer.
- Main scene: `scenes/Game.tscn` (script `scenes/game.gd`).
- Global systems are autoloads (see `project.godot`): GameManager, SpellSystem,
  DraftSystem, BandageSystem, RunStats, BossDirector, EffectSystem, TargetSystem,
  ContractGenerator, DifficultySystem, EventBus, PartyChoicePanel.
- Data lives in Resources: spells in `resources/spells/*.tres`, schools in
  `resources/specs/*.tres`, contracts and units in `data/`.

**How spells work (the building blocks):**
- A spell (`SpellData`) = cost + cast time + cooldown + **tags** + a list of **effects**
  (`resources/spells/effects/`: heal, heal-over-time, shield, delayed heal, protection,
  death save, extend HoTs, echo mark, consume shields, mana). Card text is generated from
  the effects, so it always matches the numbers.
- What an effect leaves on a fighter is a **status** (`components/statuses/`), held by
  `HealthComponent`, which reports ticks and endings to `EffectSystem`.
- `EffectSystem` is the one place healing happens; it runs every passive's hooks
  (`resources/spells/passives/PassiveRule.gd`) and announces events on `EventBus`
  (healed, hot_ticked, shield_absorbed, shield_ended, combo_fired …).
- Add a spell = a new `.tres` in `resources/spells/` built from existing effects; a new
  mechanic = a new effect/status/passive class. Ranks share `rank_family`.
- `DraftSystem` owns the school pick, the pick schedule, offers, the caps (5 spells + 3
  passives) and rank-ups.
- **Battlefield rules** are `PassiveRule`s in `resources/rules/`, active for everyone unless a
  passive you own lists their `rule_id` in `negates`. `EffectSystem.active_rules()` = rules
  in force + your passives. Effects and passives can answer `would_combo()` (spell glow).
- `BandageSystem` (Space channel, charges), `RunStats` (effective healing for the summary and
  leaderboard), `BossDirector` (the Crimson Baron's phases; uses `TargetSystem.telegraph()`).

## Folder layout
- `autoload/systems/` — game-wide logic (rounds, spells, targets, difficulty, contracts)
- `autoload/events/EventBus.gd` — shared signals; systems talk through these
- `components/` — reusable node components (HealthComponent) and `statuses/`
- `entities/` — the party member scene (Target)
- `scenes/`, `ui/` — main game scene and panels
- `data/`, `resources/` — data definitions and .tres files (`resources/spells/effects`,
  `resources/spells/passives`, `resources/specs`)
- `tools/tests/` — automated checks (see its README); `sim_bot.gd` plays real runs for balance

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
- When the owner asks for a whole phase at once, it goes in **one branch and one PR for the
  phase**, with one commit per roadmap issue, and the PR closes all of them.
- The owner approves in chat by saying **"merge #N"**; Claude merges only the PR named.
  Merging to `master` deploys to https://marz.gg/games/pythio/ automatically.
- Start a new session by reading `docs/roadmap.md` → "Where we are", then
  `docs/game-design.md`. Keep "Where we are" current at the end of each batch of work.
- Testing without a screen: `godot --headless --script <test>.gd` drives the game; real
  screenshots via `xvfb-run godot --rendering-driver opengl3 --script <shot>.gd`.

## Working rules
- One feature or fix per pull request, on its own branch. Never push to `master` directly.
- Keep file names' capitalization consistent with how they're referenced (the game must
  run on Windows, Mac and Linux).
- Prefer EventBus signals over systems calling each other directly.
- Tunable numbers (damage, mana, rewards) belong in DifficultySystem/ContractGenerator
  exports or .tres data, not hard-coded in logic.
- Don't commit Godot `*.tmp` files or the `.godot/` folder.
- Don't change art direction, add new mechanics, or rename spells without the owner's OK.
