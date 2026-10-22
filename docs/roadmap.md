# Pythio: roadmap

_Last updated: 2026-10-22. Owner: Marz. Claude works through this list one pull request at a time._

> **This file is the work plan.** What the game *is* (rules, numbers, decisions) lives in
> `docs/game-design.md`, which wins over every other design doc.

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
- **✅ Phase C done 2026-10-21 (PR #57, live, owner playtested):** fairer
  difficulty curve (bot's first deaths ~rounds 6–7, was 3–5) · passive tray (5 spells +
  3 passives) · one "next party" screen · combo-ready glow on spell buttons · bandages
  (Space) · battlefield rules with mirrored passives (Bulwark, Second Wind, Overflow) ·
  effective healing, run summary and a new rounds-then-healing leaderboard (older boards
  browsable by build with ◀ ▶, #58 fixed the arrows on the web) · the Crimson Baron
  fight in three telegraphed phases.
- **Owner feedback on Phase C (2026-10-21):** likes the gold flash when a passive fires;
  reaching the Baron is fairly easy and it gets harder from there; bandages are fine for
  now (maybe a universal spell later, or a consumable if a shop arrives); asked for an
  Escape menu (#60), "Add a passive" wording on the pick screen (#59), and a later phase
  for fonts, names and flavour text (Phase G, #61).
- **✅ Merged 2026-10-22:** "Add a passive" wording on the pick screen (#59), Escape menu (#60),
  Phase G added to the roadmap (#62).
- **Game design doc (2026-10-22):** `docs/game-design.md` is now the single source of truth
  for what Pythio is; CLAUDE.md, `design-direction.md` and `spells.md` point to it. Owner
  decisions that came with it: one Next party screen (contract choice stays parked, #55);
  gold means combos only, so the mana bar changes colour in Phase F (#63); pick pacing is an
  open question to settle after the Phase D playtest (game-design.md, open questions).
- **Next up:** Phase D (debuffs and cleanses, #23, #53). Before building it, read open
  question 1 in `docs/game-design.md` (the round-5 cleanse vs. only 2 picks per run).
- **Known rough spots:** stand-in art (new spells reuse 4 icons) · no sound · early rounds
  may now be on the easy side (watch it as Phase D adds debuffs from round 6).

**Tracked on GitHub:** each phase is a milestone and each bullet is an issue (label
`roadmap`): https://github.com/MarcialPimentel/pythio-godot/milestones. A PR says
"Closes #N", so merging it ticks the issue off and fills the phase's progress bar.
This file is the plan; GitHub shows the progress.

## The game and how builds work
Described in **`docs/game-design.md`** (pitch, pillars, loop, schools and picks, tags and
combos, rules and mirrors, bandages, scaling, the Baron, scoring, controls). Not repeated
here so the two can't drift apart.

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

### Phase C: New spells, mechanics and changes (from Phase B playtest)  — ✅ done 2026-10-21 (PR #57)
- ✅ #31 **Difficulty curve:** one more fighter every 2 rounds (cap 8), softer damage
  growth; a new player's first deaths around rounds 6–8.
- ✅ #49 **Passive tray:** 3 gold slots next to the spell bar (shared with keystones later);
  Q–T only for spells you cast.
- ✅ #29 **One "next party" screen** instead of two near-identical contracts; the Baron
  keeps his own card.
- ✅ #50 **Combo-ready glow:** a spell button glows gold when casting it on the hovered
  fighter would fire a combo.
- ✅ #51 **Bandages:** Space on a hovered fighter channels ~40 healing over ~2.5s; 3 charges
  max, +1 every 2 rounds.
- ✅ #52 **Battlefield rules and mirrored passives:** diminishing shields ↔ Bulwark,
  exhaustion at 0 mana ↔ Second Wind, soft saturation on overheal ↔ Overflow.
- ✅ #32 **Effective healing, run summary and leaderboard:** rank by rounds then effective
  healing; game-over stats (effective healing, overheal %, mitigated, spells, combos);
  a new board for the new scoring; earlier boards stay browsable by build (◀ ▶ arrows).
- ✅ #30 **Crimson Baron fight** with telegraphed phases.

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
- ⬜ #63 **Mana bar off gold,** so gold only ever means combos (owner, 2026-10-22).

### Phase G: Words, names and flair (owner-led)
- ⬜ #61 **Fonts, spell names, descriptions and flavour:** the owner goes through all
  on-screen text and adds flair; Claude exports every line into one editable list, then
  applies the edits in one PR.

## Backlog (parked on purpose)
#38 duo spells · #39 rerolls for spell picks · #40 skill tree / meta-progression ·
#41 pet and positional spells (Decoy, Healing Spirit, Soulbond, Hallowed Ground) ·
#54 raid mode (10–25 fighters with compact raid frames) · #55 contract choice with reward
and threat previews ·
click-casting with mouse button + modifier bindings (the original web game's input model) ·
gold and a shop (bandages could become a shop consumable, or a universal spell) · better scoring · difficulty modes · achievements.

## Decisions and open questions
Recorded in `docs/game-design.md`: owner decisions are marked **[Decided]** in each
section, and the open questions are in "Open questions for Marz". The reasoning behind the
2026-10-21 decisions is in `docs/design-direction.md`.
