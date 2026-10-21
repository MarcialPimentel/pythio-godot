# Pythio: roadmap

_Last updated: 2026-10-21. Owner: Marz. Claude works through this list one pull request at a time._

## ▶ Where we are (read this first in a new session)
- **Live:** https://marz.gg/games/pythio/ (deploys automatically when a PR merges into
  `master`; see `docs/deploy.md`). The original JS version is at `games/pythio-classic/`.
  Every build shows a build number bottom-right; it should match the latest Actions run.
- **Direction changed 2026-10-21:** the game is **endless** again (the 5-round run was a
  pilot). Builds come from a **specialization** pick at the start and a **new spell every
  5 rounds**, capped, so a run reaches a "build complete" point and then it's about how
  far you can take it. Full reasoning: `docs/design-direction.md`.
- **Done (PRs #5–#35):** game launches · round flow · casting (hover + Q/W/E, cast times,
  mana, cooldowns) · fighters (death ends run, armor HP/damage, character types) · noir
  graphics with stand-in art · web build + FTP deploy · online leaderboard · build number
  in the corner (#18) · roadmap tracked on GitHub (#35).
- **Next up:** #36 endless rounds → #19 bursts hit → #20 debug panel → Phase B.
- **Waiting on owner:** playtest feedback after Phase A · spell numbers review in #22.
- **Known rough spots:** today the game stops after round 5 · only 3 spells, all given at
  the start · combos are a console-only placeholder · stand-in art is low-res · no sound.

**Tracked on GitHub:** each phase is a milestone and each bullet is an issue (label
`roadmap`): https://github.com/MarcialPimentel/pythio-godot/milestones. A PR says
"Closes #N", so merging it ticks the issue off and fills the phase's progress bar.
This file is the plan; GitHub shows the progress.

## The game in one paragraph
Real-time, high-APM "plate spinning" healing in the style of WoW healer raid frames,
combined with roguelite build-crafting. Rounds never stop until a fighter dies. You pick
a school at the start, add a spell every 5 rounds, and the spells you combine (through
plain-language tags) decide how you play. Every run should tempt you to try a different
combination next time.

## How builds work (the design spine)
- **Specialization (run start):** pick 1 of 3 schools, each with its starter spell:
  **Mending** (Heal, direct heals), **Bloom** (Renew, heals over time),
  **Ward** (Shield, shields and damage reduction).
- **Spell picks:** after every 5th round, pick 1 of 3. Offers favour your school and
  always include one off-school card (splashing is where creative builds come from).
  Spellbook cap: 5 spells (keys Q–T), so the build is complete at round 20.
  Cadence, first-pick round and cap are settings, so playtests can try alternatives.
- **Ranks, not duplicate spells:** Lesser Heal / Heal / Greater Heal are one spell with
  ranks (Heal I → II → III); likewise Renew → Rejuvenation, Cleanse → Purify. A rank-up
  appears as a pick option, so "go deeper or go wider?" is a real choice.
- **Keystones (Phase D):** every 10 rounds, a rule-changing pick, capped.
- **Synergies through plain-language tags** (Balatro-style): spell text names tags like
  **Direct**, **Heal-over-Time**, **Shield**, **Cleanse**, **Delayed**, **Multi-target**,
  and combo spells react to any spell with that tag ("Extends your **Heal-over-Time**
  effects by 5s"). A new spell automatically combines with everything sharing its tag.
  When a combo fires: golden flash and a dry Pythio quip.
- **Balance rule:** fast, efficient, big — pick two. Fast spells cost more mana per HP;
  slow spells are the efficient ones. No spell is better than another on every axis.
- **Every spell needs a threat that asks for it:** shields ↔ telegraphed spikes,
  HoTs/Chain Heal ↔ party-wide damage, Cleanse ↔ damage over time, Guardian Angel ↔
  execute moments. Spells and damage patterns are designed together.

## Phases
Each phase ends with a **playtest checkpoint**: Marz plays a few runs and gives feedback.
One bullet ≈ one pull request.

### Phase A: Endless rounds
- ⬜ #36 **Endless rounds:** no cap; rounds 15s growing 1s/round to a 25s cap; the Crimson
  Baron every 5th round, tougher each time; scaling continues; leaderboard accepts any round.
- ⬜ #19 **Bursts actually hit** after their warning (so Shield has a job).
- ⬜ #20 **Debug panel (F1):** +50 mana, skip round, jump to round N, damage/heal a fighter, god mode.

### Phase B: Picking spells and new spells (the core)
- ⬜ #21 **Effect system with plain-language tags** (no visible change; the foundation).
- ⬜ #24 **Pick a specialization** at the start of a run (Mending / Bloom / Ward).
- ⬜ #25 **Pick a new spell every 5 rounds,** capped at 5, with rank-ups as options.
- ⬜ #22 **First new-spell batch, rebalanced** (ranks collapsed; owner reviews numbers).
- ⬜ #26 **Combo spells driven by tags:** Overgrowth, Echo Healing, a shield-break payoff.
- ⬜ #27 **Remaining spells by school,** including passives and prerequisites.
- ⬜ #28 **Synergy hints on pick cards** and a spellbook panel showing your build mid-run.

### Phase C: Damage worth reacting to
- ⬜ #23 **Damage patterns by role:** damage over time, escalating DoTs, debuff icons.
- ⬜ #29 **Contracts show a reward and a threat preview** (Hades-door style), so the choice matters.
- ⬜ #30 **Crimson Baron fight** with telegraphed phases.
- ⬜ #31 **Tuning pass** for endless play (round lengths, scaling, mana, spell numbers).

### Phase D: Keystones
- ⬜ #37 **Keystones every 10 rounds,** 1 of 3, capped.

### Phase E: Readability and feel
Done early: floating numbers, noir theme, online leaderboard (#12, #14).
- ⬜ #32 **Game-over run summary:** spells picked, healing done, combos fired.
- ⬜ #33 **Basic sound:** casts, combos, bursts, death.
- ⬜ #34 **Swap in high-res art** as it's generated (`docs/art.md`).

## Backlog (parked on purpose)
#38 duo spells · #39 rerolls for spell picks · #40 skill tree / meta-progression ·
#41 pet and positional spells (Decoy, Healing Spirit, Soulbond, Hallowed Ground) ·
click-casting with mouse button + modifier bindings (the original web game's input model) ·
gold and a shop · better scoring · difficulty modes · achievements.

## Open decisions (owner)
1. Flash Heal and Shield numbers: settled in #22 (spell batch review).
- Decided 2026-10-21: endless rounds; rounds under 30s; 3 specializations; ranks replace
  duplicate spells; a spell every 5 rounds, capped; keystones every 10, capped;
  contracts repurposed; plain-language tags; duo spells, rerolls and skill tree parked;
  gold/shop post-core.
