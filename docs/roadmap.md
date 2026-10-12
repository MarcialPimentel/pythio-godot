# Pythio: roadmap to MVP

_Last updated: 2026-10-12. Owner: Marz. Claude works through this list one pull request at a time._

## What "MVP done" means
A complete **5-round run**: draft your spells → pick a contract → survive the round →
pick an upgrade → … → beat or fall to the Crimson Baron in round 5 → see your run
summary and score. Two runs with different picks should **play differently**. That is
the roguelite synergy promise, and it's the core feature.

Grading scale: 1 = not started · 2 = built, not refined · 3 = nearly complete · 4 = MVP-done.

| System | Today | After phase |
|---|---|---|
| Round structure and loss | 2 | 4 after Phase 1 |
| Spells and casting | 2 | 3 after Phase 1, 4 after Phase 2 |
| Mana | 2 | 4 after Phase 1 |
| Health visuals | 2 | 3 after Phase 1, 4 after Phase 5 |
| Debug panel | 1 | 4 after Phase 1 |
| Target generation and armor | 2 | 3 after Phase 1, 4 after Phase 2 |
| Damage patterns | 2 | 4 after Phase 2 |
| **Synergies (combos + upgrades)** | 1 | 4 after Phase 3 |
| Contracts, modifiers and boss | 3 / 1 | 4 after Phase 4 |
| Screens, VFX, leaderboard | 2 / 1 | 4 after Phase 5 |

## How synergies will work (the design spine)

The spell list's synergies are mostly fixed pairs ("Renew + Healing Plague = +3s"). Pairs
multiply with every new spell, and small % bonuses are hard to feel. Instead, every spell
gets **tags**, and synergies key off tags and events. Any HoT spell then works with any
HoT upgrade, and new spells slot into existing builds for free.

- **Tags:** `DIRECT`, `HOT`, `SHIELD`, `CLEANSE`, `DELAYED`, `MULTI`
- **Events synergies listen for:** cast, heal, overheal, HoT tick, shield absorbs,
  shield breaks, cleanse, heal during a burst warning

**Layer 1: in-fight combos (every run, the WoW-healing feel).** Built in, golden-yellow
flash and a Pythio quip when they fire:
- **Quicken:** a `DIRECT` heal on a target with a HoT consumes the HoT's remaining
  healing as an instant burst.
- **Overflow:** overhealing becomes a small shield, so wasted heals aren't wasted.
- **Clutch:** healing a fighter during a burst warning refunds mana.

**Layer 2: run upgrades (the roguelite build).** You start by **drafting 3 spells of the 6
in the Universal Pool** (Q/W/E). After rounds 1–4 you pick **1 of 3 upgrades**. At least
one offer gives a 4th spell for the R key. Upgrades are drawn from the spell list and
pushed toward three builds:

| Build | Core spells | Upgrades that feed it |
|---|---|---|
| **Bloom (HoT)** | Renew | Overgrowth, Lifebloom, Aura of Mending, "Quicken leaves a 2s HoT" |
| **Bulwark (shield)** | Shield | Guardian Ward, Spirit Surge, "Overflow shields don't expire", Guardian Angel |
| **Surgeon (direct)** | Heal, Flash Heal, Chain Heal | Echo Heal, Mend Wounds, Vital Bond, Seraphic Blessing |

### Spell list review: what goes in the MVP
- **In the MVP:** all 6 Universal Pool spells, using the numbers from `docs/spells.md`
  as the baseline. About 12 upgrades: Lifebloom, Spirit Surge, Overgrowth, Echo Heal,
  Guardian Angel, Mend Wounds, Guardian Ward, Greater Heal, plus passives Seraphic Blessing,
  Aura of Mending, Vital Bond and Shared Harmony, and combo boosters like the ones above.
- **Passive "spells" become upgrades:** Aura of Mending, Seraphic Blessing and Vital Bond
  aren't cast, so they live in the upgrade pool.
- **Post-MVP:** Keystones (they're chosen at rounds 10/20, which a 5-round run never
  reaches), Rejuvenation, Healing Plague, Harmonize, Time Stop, Divine Channel, Tranquility,
  Fountain of Light, Aegis of Light.
- **Need a rethink before use:** Hallowed Ground and Soulbond assume positioning, and the
  party is a single row. "Adjacent" can mean the neighbour in the row, but "area" has no
  meaning yet.
- **Duplicates to resolve:** Lifebloom appears twice with different effects
  (50 HP after 10s, and a 40 HP burst at the end). Cleanse and Purify, and Shield,
  Guardian Ward, Foresight Ward and Aegis of Light, overlap. Each will need a clear
  difference.
- **Cleanse needs something to cleanse,** so damage-over-time effects (Phase 2) come
  before Cleanse is worth drafting.

## Phases
Each phase ends with a **playtest checkpoint**: Marz plays a few runs and gives feedback
before the next phase starts. One bullet ≈ one pull request.

### Phase 1: The core loop actually works
Goal: a full 5-round run you can genuinely win or lose.
1. **Casting:** hover a fighter and press Q/W/E/R. Cast times with the cast bar, cooldowns
   that count down, spells cost mana, and the mana bar is visible with numbers.
2. **Fighters:** death ends the run, armor rolls correctly, HP comes from armor
   (100/75/50, scaled by round), armor damage multipliers apply, health bars scale to max
   HP, and each fighter shows an armor icon and "80/100 (+8.0s)" text. Reuse that code from
   the old `scenes/panel_container.gd`, then delete it and the unused party presets.
3. **Round flow:** round lengths from the original design (10s, then 20s and up), half your
   max mana restored at round start, casting stops when the round ends, Play Again works,
   and the high score refreshes.
4. **Debug panel (F1):** +50 mana, skip round, damage or heal a fighter, god mode.

### Phase 2: Spells and damage worth reacting to
Goal: the six starting spells feel distinct, because the damage gives each one a job.
1. **Effect pipeline:** spell tags and events (no visible change; it lays the track for
   synergies).
2. **Universal Pool:** Heal, Renew, Shield, Flash Heal, Chain Heal and Cleanse at the
   spell list's numbers.
3. **Damage patterns by role:** bursts that actually hit after their warning,
   damage over time, escalating damage over time, and an icon showing when a fighter has
   a debuff.
4. **Starting draft screen:** pick 3 of 6 spells for Q/W/E.

### Phase 3: Synergies (the core feature)
Goal: two runs with different picks feel different.
1. **In-fight combos:** Quicken, Overflow and Clutch, each with a golden flash and quip.
2. **Upgrade pick screen** after rounds 1–4, with the first 6 upgrades.
3. **Full upgrade pool** (~12), balanced across Bloom, Bulwark and Surgeon.
4. **R-slot spell offers** and a run-build panel showing what you've picked.

### Phase 4: Run structure and difficulty
Goal: contracts are a real risk-or-reward decision, and round 5 is a fight.
1. **Contract risk shown,** with higher risk bringing round modifiers (Double Damage,
   Fast Attacks) announced in a red banner.
2. **Gold has a purpose** (see open decisions).
3. **Crimson Baron fight:** a boss with telegraphed phases, not just a big health bar.
4. **Tuning pass,** using the debug panel.

### Phase 5: Readability and feel
Goal: you can read the chaos at a glance, and it looks and sounds like Pythio.
1. **Floating heal and damage numbers,** using the color language (emerald heal,
   electric-blue shield, gold combo, red danger).
2. **Noir UI theme pass.**
3. **Game-over run summary:** builds picked, healing done, combos fired, plus a local
   top-10 leaderboard with name entry.
4. **Basic sound:** casts, combos, bursts, death.

**MVP complete.**

## After the MVP (parking lot)
Keystones and their unlocks · the remaining spells from `docs/spells.md` ·
endless mode and talent picks every 5 rounds (original design) · online leaderboard ·
difficulty modes · specializations · achievements · positional mechanics ·
secondary objectives (bonus for keeping everyone above 50%).

## Open decisions (owner)
1. Starting draft of 3 from the 6 Universal Pool spells: confirmed?
2. Use the spell list's numbers as the baseline: confirmed?
3. What gold does in the MVP: reroll upgrade offers, a mini shop, or just score?
4. Keystones post-MVP: confirmed?
