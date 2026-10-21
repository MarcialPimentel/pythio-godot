# Pythio: roadmap to MVP

_Last updated: 2026-10-21. Owner: Marz. Claude works through this list one pull request at a time._

## ▶ Where we are (read this first in a new session)
- **Live:** https://marz.gg/games/pythio/ (deploys automatically when a PR merges into
  `master`; see `docs/deploy.md`). The original JS version is at `games/pythio-classic/`.
- **Done (PRs #5–#16):** project brief and docs · game launches · round flow (10s/20s/21s,
  mana top-up, Play Again) · casting (hover + Q/W/E, cast times, mana, cooldown system) ·
  fighters (death ends run, armor HP/damage, character types) · noir graphics overhaul with
  stand-in art from the concept sheet · web build + FTP deploy · online leaderboard
  (`web/leaderboard_godot.php`) · http→https redirect.
- **Next up:** Phase 1 leftovers (bursts actually hit · F1 debug panel), then Phase 2.
- **Waiting on owner:** feedback list from playtesting · open decisions at the bottom.
- **Known rough spots:** stand-in art is low-res (`docs/art.md` has the regeneration
  prompt pack) · Rogue sprites have white specks · no sound · boss is trivially easy ·
  score = 100 × rounds survived (all full clears tie at 1500).

## What "MVP done" means
A complete **5-round run**: draft your first spell → pick a contract → survive the round →
draft another spell into your spellbook → … → beat or fall to the Crimson Baron in
round 5 → see your run summary and score. Your spellbook grows from 1 spell to 5, and
**the spells you combine decide how you play**. Two runs with different drafts should
play differently. That is the roguelite synergy promise, and it's the core feature.

Grading scale: 1 = not started · 2 = built, not refined · 3 = nearly complete · 4 = MVP-done.

| System | Now (Oct 21) | After phase |
|---|---|---|
| Round structure and loss | 3 | 4 after Phase 4 (boss fight) |
| Spells and casting | 3 | 4 after Phase 2 |
| Mana | 4 | — (tuning only) |
| Health visuals and UI | 4 | — |
| Debug panel | 1 | 4 after Phase 1 |
| Target generation and armor | 3 | 4 after Phase 2 |
| Damage patterns | 2 | 4 after Phase 2 |
| **Spell drafting and synergies** | 1 | 4 after Phase 3 |
| Contracts, modifiers and boss | 3 / 1 | 4 after Phase 4 |
| Screens, VFX, feel | 3 | 4 after Phase 5 (sound, run summary) |
| Web build, deploy, online leaderboard | 4 | — |

## How drafting and synergies will work (the design spine)

**The spellbook is the build.** There's no separate upgrade system. Everything you pick
is a spell, and the fun comes from mixing and matching spells into combinations.

- **Opening draft:** choose **1 of 3** spells. The opening three are always spells that
  heal on their own (e.g. Heal, Renew, Flash Heal), so round 1 is survivable with one
  spell. Round 1 is the gentlest round.
- **After rounds 1–4:** choose **1 of 3** spells to add to your spellbook, so you have
  5 spells by the boss (keys Q/W/E/R/T).
- **Synergy-aware offers:** at least one of the three offers combos with a spell you
  already own, and each card says so ("Combos with Renew: …"). Combos are discoverable
  while you draft, not only by reading a wiki.
- **Some spells need others** (from the original design: Greater Heal needs Heal). A
  spell with a prerequisite only shows up once you own what it builds on. This is what
  makes certain drafts feel like a path.
- **Passive spells** (Seraphic Blessing, Aura of Mending, Vital Bond) are drafted like any
  other spell. They take a spellbook slot but no key.

**How combos are built: tags, not fixed pairs.** The spell list's synergies are mostly
fixed pairs ("Renew + Healing Plague = +3s"). Pairs multiply with every new spell, and
small % bonuses are hard to feel. Instead, every spell gets **tags**, and a combo spell
reacts to a tag. Overgrowth extends *any* HoT, Spirit Surge consumes *any* shield, Echo
Heal repeats *any* direct heal. A new spell then combines with everything that shares
its tag.

- **Tags:** `DIRECT`, `HOT`, `SHIELD`, `CLEANSE`, `DELAYED`, `MULTI`
- **Events combos listen for:** cast, heal, overheal, HoT tick, shield absorbs,
  shield breaks, cleanse, heal during a burst warning
- **When a combo fires:** golden-yellow flash and a dry Pythio quip.

Example combinations the MVP spell pool should make possible:

| Combination | What happens |
|---|---|
| Renew + Overgrowth + Lifebloom | Stack HoTs, stretch them, then cash in a delayed bloom |
| Shield + Spirit Surge | Pre-shield before a burst, then convert leftover shields into healing |
| Flash Heal + Echo Heal | Every emergency heal repeats 3s later at half strength |
| Heal + Greater Heal + Seraphic Blessing | Slow, efficient, big heals: a mana-careful build |
| Chain Heal + Aura of Mending + Vital Bond | Healing that splashes across the whole row |

### Spell list review: what goes in the MVP
- **In the MVP (~14 spells):** all 6 Universal Pool spells (Heal, Renew, Shield, Flash Heal,
  Chain Heal, Cleanse), plus Greater Heal, Lifebloom, Overgrowth, Echo Heal, Spirit Surge,
  Mend Wounds, Guardian Ward and Guardian Angel, plus passives Seraphic Blessing, Aura of
  Mending and Vital Bond. Numbers from `docs/spells.md` are the baseline.
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

### Phase 1: The core loop actually works  — 3 of 5 done
Goal: a full 5-round run you can genuinely win or lose.
- ✅ #9 casting · ✅ #10 fighters · ✅ #8 round flow
- ⬜ **Bursts actually hit** after their warning (moved up from Phase 2, so Shield has a job)
- ⬜ **Debug panel (F1)**

Original scope, for reference:
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
4. **Opening draft screen:** pick 1 of 3 healing spells to start the run.

### Phase 3: Spell drafting and synergies (the core feature)
Goal: two runs with different drafts feel different.
1. **Between-round draft screen:** after rounds 1–4, pick 1 of 3 spells to add
   (keys Q–T). Spell cards show cost, cast time and tags.
2. **Combo spells:** Overgrowth, Echo Heal, Spirit Surge, Lifebloom, with the golden flash
   and quip when a combo fires.
3. **Full MVP pool (~14 spells)** including passives and prerequisites (Greater Heal
   needs Heal).
4. **Synergy-aware offers and hints:** at least one offer combos with your spellbook, the
   card says what it combos with, and a spellbook panel shows your build mid-run.

### Phase 4: Run structure and difficulty
Goal: contracts are a real risk-or-reward decision, and round 5 is a fight.
1. **Contract risk shown,** with higher risk bringing round modifiers (Double Damage,
   Fast Attacks) announced in a red banner.
2. ~~Gold has a purpose~~ — **out of MVP scope** (gold was for a future shop).
3. **Crimson Baron fight:** a boss with telegraphed phases, not just a big health bar.
4. **Tuning pass,** using the debug panel.

### Phase 5: Readability and feel  — mostly done early (#12, #14)
Goal: you can read the chaos at a glance, and it looks and sounds like Pythio.
Remaining: game-over run summary (spells, healing done, combos) · basic sound ·
swap in high-res art as it's generated. Floating numbers, noir theme and the online
leaderboard are done.
1. **Floating heal and damage numbers,** using the color language (emerald heal,
   electric-blue shield, gold combo, red danger).
2. **Noir UI theme pass.**
3. **Game-over run summary:** builds picked, healing done, combos fired, plus a local
   top-10 leaderboard with name entry.
4. **Basic sound:** casts, combos, bursts, death.

**MVP complete.**

## After the MVP (parking lot)
Keystones and their unlocks · the remaining spells from `docs/spells.md` ·
endless mode and talent picks every 5 rounds (original design) · gold and a shop ·
better scoring (efficiency, fighters kept healthy) · smaller web download ·
difficulty modes · specializations · achievements · positional mechanics ·
secondary objectives (bonus for keeping everyone above 50%).

## Open decisions (owner)
1. Five spells by the boss (keys Q/W/E/R/T, as the spell bar now shows), or a cap of 4
   with the option to swap one out?
2. Spell numbers: keep today's values (Flash Heal 45 HP instant, Shield 55/8s) or switch to
   `docs/spells.md` (Flash Heal 40 HP, 1s cast, 5s cooldown; Shield 30/5s)?
3. Keystones post-MVP: confirmed?
- Decided: gold/shop is post-MVP (2026-10-21).
