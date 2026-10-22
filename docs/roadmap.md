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
- **✅ Phase A done 2026-10-21 (Build 30, owner playtested):** endless rounds (#43),
  bursts land after their warning and shields absorb them (#45), F1 debug panel (#46,
  works on the live site; debug runs can't be posted to the leaderboard).
- **Done before that (PRs #5–#44):** game launches · round flow · casting (hover +
  Q/W/E, cast times, mana, cooldowns) · fighters (death ends run, armor HP/damage,
  character types) · noir graphics with stand-in art · web build + FTP deploy · online
  leaderboard · build number in the corner (#18, #44) · roadmap tracked on GitHub (#35).
- **Deploys:** GitHub uploads to marz.gg/games/pythio/ (`FTP_SERVER_DIR` = `pythio/`,
  fixed 2026-10-21). The old `games/pythio-godot/` folder is unused and can be deleted.
- **✅ Phase B done 2026-10-21 (Build 33, PR #48, owner playtested):** pick a school
  (Mending / Bloom / Ward) → spell picks after round 1 and every 5 rounds (cap 5, rank-ups,
  build complete) → 25 spells incl. combo spells and passives → tag-based combos with gold
  flash and quips → synergy hints on cards and a build summary. Spell table: `docs/spells.md`.
- **Owner feedback on Phase B (2026-10-21):** pleased overall; the game is hard (hasn't
  passed round 4 — "not a bad thing"); likes passives and flavour but wants them off the
  Q–T bar; the two contracts are a non-choice; wants spells to flash when a combo is ready;
  new ideas: bandages, battlefield rules that mirror passives, debuffs needing cleanses,
  effective healing on the leaderboard, raid-size parties later.
- **Phase C built 2026-10-21 (one PR for the whole phase, awaiting owner review):** fairer
  difficulty curve (bot's first deaths ~rounds 6–7, was 3–5) · passive tray (5 spells +
  3 passives) · one "next party" screen · combo-ready glow on spell buttons · bandages
  (Space) · battlefield rules with mirrored passives (Bulwark, Second Wind, Overflow) ·
  effective healing, run summary and a fresh rounds-then-healing leaderboard · the Crimson
  Baron fight in three telegraphed phases.
- **Next up:** owner playtests Phase C → Phase D (debuffs and cleanses, #23, #53).
- **Waiting on owner:** Phase C review and playtest.
- **Known rough spots:** stand-in art (new spells reuse 4 icons) · no sound · the old
  leaderboard file (`leaderboard_godot.json`) is left on the server but no longer read.

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
- **Spell picks:** after round 1, then after every 5th round, pick 1 of 3. Offers favour
  your school and always include one off-school card (splashing is where creative builds
  come from), and at least one combos with what you own when possible.
- **Two kinds of slot:** 5 spells you cast (keys Q–T) and **3 passive slots** (a tray next
  to the spell bar, shared with keystones). The build is complete when both are full and
  no rank-ups are left; then the run is about how far it goes.
- **Ranks, not duplicate spells:** Lesser Heal / Heal / Greater Heal are one spell with
  ranks (Heal I → II → III); likewise Renew → Rejuvenation, Cleanse → Purify. A rank-up
  appears as a pick option, so "go deeper or go wider?" is a real choice.
- **Battlefield rules and their mirrors:** the battlefield has rules that reward careful
  play (diminishing shields, mana exhaustion, soft saturation on overheal). Passives and
  keystones can flip a rule in your favour (Bulwark, Second Wind, Overflow). Debuffs and
  buffs are the same kind of thing with the sign flipped.
- **Bandages:** a panic button on its own resource — Space on a hovered fighter channels a
  heal; up to 3 charges, +1 every 2 rounds.
- **Keystones (Phase E):** every 10 rounds, a rule-changing pick that takes a passive slot.
- **Score:** rounds survived, then effective healing (health restored without overheal +
  damage absorbed or prevented).
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

### Phase A: Endless rounds  — ✅ done 2026-10-21
- ✅ #36 **Endless rounds:** no cap; rounds 15s growing 1s/round to a 25s cap; the Crimson
  Baron every 5th round, tougher each time; scaling continues; leaderboard accepts any round.
- ✅ #19 **Bursts actually hit** after their warning (so Shield has a job).
- ✅ #20 **Debug panel (F1):** +50 mana, skip round, jump to round N, damage/heal a fighter, god mode.

### Phase B: Picking spells and new spells (the core)  — ✅ done 2026-10-21 (PR #48)
- ✅ #21 **Effect system with plain-language tags** (the foundation).
- ✅ #24 **Pick a specialization** at the start of a run (Mending / Bloom / Ward).
- ✅ #25 **Spell picks** after round 1, then every 5 rounds; capped at 5, with rank-ups.
- ✅ #22 **First spell batch, rebalanced** (ranks collapsed).
- ✅ #26 **Combo spells driven by tags:** Overgrowth, Echo Healing, Spirit Surge.
- ✅ #27 **Remaining spells by school,** including passives and prerequisites.
- ✅ #28 **Synergy hints on pick cards** and a build summary above the spell bar.

### Phase C: New spells, mechanics and changes (from Phase B playtest)  — 🔶 built, in review (one PR)
- 🔶 #31 **Difficulty curve:** one more fighter every 2 rounds (cap 8), softer damage
  growth; a new player's first deaths around rounds 6–8.
- 🔶 #49 **Passive tray:** 3 gold slots next to the spell bar (shared with keystones later);
  Q–T only for spells you cast.
- 🔶 #29 **One "next party" screen** instead of two near-identical contracts; the Baron
  keeps his own card.
- 🔶 #50 **Combo-ready glow:** a spell button glows gold when casting it on the hovered
  fighter would fire a combo.
- 🔶 #51 **Bandages:** Space on a hovered fighter channels ~40 healing over ~2.5s; 3 charges
  max, +1 every 2 rounds.
- 🔶 #52 **Battlefield rules and mirrored passives:** diminishing shields ↔ Bulwark,
  exhaustion at 0 mana ↔ Second Wind, soft saturation on overheal ↔ Overflow.
- 🔶 #32 **Effective healing, run summary and leaderboard:** rank by rounds then effective
  healing; game-over stats (effective healing, overheal %, mitigated, spells, combos);
  the leaderboard starts fresh.
- 🔶 #30 **Crimson Baron fight** with telegraphed phases.

### Phase D: Debuffs and cleanses
- ⬜ #23 **Debuffs from round 6:** Poison (stacking DoT → Cleanse), Hex (−50% healing taken
  → Purify), Bleed (ends when healed above ~80% or bandaged); maybe Doom later.
- ⬜ #53 **Cleanse and Purify** with a new Cleanse tag; the round-5 pick always offers a cleanse.

### Phase E: Keystones
- ⬜ #37 **Keystones every 10 rounds,** 1 of 3, built from the mirrored battlefield rules;
  they share the 3 passive slots.

### Phase F: Readability and feel
Done early: floating numbers, noir theme, online leaderboard (#12, #14).
- ⬜ #33 **Basic sound:** casts, combos, bursts, death.
- ⬜ #34 **Swap in high-res art** as it's generated (`docs/art.md`).

## Backlog (parked on purpose)
#38 duo spells · #39 rerolls for spell picks · #40 skill tree / meta-progression ·
#41 pet and positional spells (Decoy, Healing Spirit, Soulbond, Hallowed Ground) ·
#54 raid mode (10–25 fighters with compact raid frames) · #55 contract choice with reward
and threat previews ·
click-casting with mouse button + modifier bindings (the original web game's input model) ·
gold and a shop · better scoring · difficulty modes · achievements.

## Open decisions (owner)
- Decided 2026-10-21: endless rounds; rounds under 30s; 3 specializations; ranks replace
  duplicate spells; a spell every 5 rounds, capped; keystones every 10, capped;
  contracts repurposed; plain-language tags; duo spells, rerolls and skill tree parked;
  gold/shop post-core.
- Decided 2026-10-21 (after Phase B playtest): passives get their own 3 slots, shared with
  keystones; bandages on Space while hovering; the soft overheal rule (next heal weaker);
  debuffs and cleanses come after Phase C; leaderboard ranks by rounds, then effective
  healing, and starts fresh; one "next party" screen instead of two contracts; raid mode
  is a backlog idea.
