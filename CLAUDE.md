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
fighter dies. The Crimson Baron returns every 5th round. After round 1 and then every 5 rounds
you pick a new spell (5 spells on Q–T + 3 passive slots); later, a keystone every 10 rounds
(takes a passive slot). Bandages (Space on a hovered fighter) are a panic button with a few
charges. Score = rounds survived, then effective healing.

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
- **Battlefield rules ↔ mirrored passives:** penalties for sloppy play (diminishing
  shields, mana exhaustion, soft saturation on overheal) are rules; passives and keystones
  can flip them (Bulwark, Second Wind, Overflow). Debuffs and buffs share one rule system.
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

**Combos:** spells react to **tags**, not to fixed partners: Overgrowth extends any
Heal-over-Time, Echo Healing repeats any Direct heal, Spirit Surge cashes in any Shield,
passives (Aura of Mending, Vital Bond…) react to tag events. When one fires: gold text,
gold flash, sometimes a Pythio quip.

## Tech
- Godot **4.3**, GDScript, GL Compatibility renderer.
- Main scene: `scenes/Game.tscn` (script `scenes/game.gd`).
- Global systems are autoloads (see `project.godot`): GameManager, SpellSystem,
  DraftSystem, EffectSystem, TargetSystem, ContractGenerator, DifficultySystem, EventBus,
  PartyChoicePanel.
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
- `DraftSystem` owns the school pick, the pick schedule, offers, the cap and rank-ups.

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
