# Pythio: game design

_Owner: Marz. Started 2026-10-22 from the live game (Build after PR #62) and the design docs._

## How to use this document

- **This is the single source of truth for what Pythio is.** When it disagrees with any
  other design doc (`design-direction.md`, `design.md`, `spells.md`), this one wins.
- **The roadmap (`docs/roadmap.md`) is the work plan.** It says *what we build next*. This
  document says *what the game is* and *why*.
- **Marz edits this freely.** Change a sentence, a number or a decision. If you change a
  number here, the game doesn't change until the file named next to it changes too (ask
  Claude to do that in a PR).
- **Claude (and any AI session) reads this before making a design decision,** and checks
  every change against the pillars. If a request would weaken a pillar, say so and suggest
  a better option. Marz makes the final call.
- **Two kinds of statement:**
  - **[Decided]**: Marz's decision. Don't change it without his OK.
  - **[Proposed]**: Claude's suggestion, waiting for Marz. Treat it as an idea, not a rule.
  - Anything without a mark describes how the game works today (it's in the code).
- **Where the numbers live:** the tables give each tunable number and the file it lives
  in. The code is the truth for numbers. If a table here disagrees with the file, the
  file is what's live: fix the table.
- **Other docs, and what each is for:**
  - `docs/spells.md`: the spell catalog, with every spell's real numbers.
  - `docs/design-direction.md`: the 2026-10-21 design review. It's frozen: it records
    *why* we decided things back then.
  - `docs/design.md`: the original web game's design doc. Use it for ideas only.
  - `docs/art.md`: the art style guide and file names.
  - `tools/tests/README.md`: what each automated test checks.

---

## 1. Pitch and pillars

**Pitch [Decided].** World of Warcraft–style healing (raid frames, high-APM plate spinning,
mana as the long game, reading incoming damage) combined with the spell synergies and
build-crafting of a roguelite. You are Pythio, a battlefield healer for hire. Wounded
fighters take damage non-stop, rounds keep coming, and any death ends the run. Every run
should play differently because of the spells you picked and how they combine.

**Pillars [Decided].** Check every change against these four.

1. **Triage pressure.** You can never fully keep up, so you must prioritize.
2. **Meaningful choices.** Which spell, which target, when to combo, when to save mana.
   Every pick should be a real choice; a non-choice weakens trust in all the others.
3. **Escalating chaos.** Rounds get harder and more chaotic.
4. **Readable feedback.** Health bars, warnings, mana costs and spell responses stay clear
   even when things get intense.

**Design rules that follow from the pillars [Decided]:**
- **Fast, efficient, big: pick two.** No spell is better than another on every axis.
  Slow casts are the mana-efficient ones; instant or big heals cost more per point healed.
- **Every spell needs a threat that asks for it.** Shields ↔ warned bursts;
  heals-over-time and Chain Heal ↔ party-wide damage; Cleanse ↔ damage over time (Phase D);
  Guardian Angel ↔ execution moments. Spells and damage patterns are designed together.
- **Every spell is good on its own and better with friends.** That's how "no bad pick" holds up.
- **High APM comes from many short decisions, not long casts.** Most spells are instant
  to 1.5s; long casts are deliberate gambles (Divine Channel).
- **Build from systems, not special cases.** A new spell is data (a `.tres` file) built
  from existing effects. A new mechanic is a new effect, status or rule that every spell
  can use.

## 2. Tone and look

**[Decided]**
- **Tone:** darkly humorous noir. Pythio speaks in dry, understated one-liners (round start,
  the Baron, low mana, combos, death, picks). He's a professional who charges by the hour.
- **Look:** gritty inked-comic noir. Heavy black linework, grey and sepia figures, dark
  high-contrast UI. Colour appears only where it means something.
- **Colour language** (one meaning per colour, so a glance is enough):

| Colour | Means |
|---|---|
| Emerald green | Healing |
| Electric blue | Shields |
| Gold | Combos and powerful effects: a gold flash always means a combo fired |
| Blood red | Danger: bursts, warnings, wounds |

- **Gold means combos only [Decided 2026-10-22].** Today the mana bar is also gold. It will
  move to another colour in Phase F (see Planned features).
- **Fonts:** Pirata One (titles), Oswald (UI), Special Elite (Pythio's speech), DejaVu
  (symbols). Files: `assets/fonts/`. The Phase G pass may change these.
- **Art:** stand-ins cut from a concept sheet. The style guide, file names and prompt pack
  are in `docs/art.md`.

## 3. The core loop

**Run start.** Pick a school (Mending, Bloom or Ward). You start with that school's one spell.

**Each round:**
1. **Next party screen:** shows who you'll heal (how many fighters, which kinds, which
   armour). Press Ready (Space). On Baron rounds the screen says "The Crimson Baron sends for you".
2. **The round:** a timer counts down. Every fighter takes steady damage. Every few seconds
   one fighter gets a **burst warning** (red ring, "INCOMING"), then takes a big hit. You
   heal, shield and protect with spells (mana) and bandages (charges).
3. **Survive the timer** and the round is cleared. **Any fighter dies** and the run is over.
4. **Between rounds:** after round 1 and after every 5th round, you pick a new spell or
   passive (1 of 3). Your mana carries over and tops up by half your max pool. Cooldowns
   reset. A new party comes in at full health.

**Endless [Decided].** Rounds never stop until someone dies. Your score is how far you got.

**Round length [Decided: stay under 30s].** Round 1 lasts 15s, and each round adds 1s up to
a 25s cap. The pace stays frantic.

**Losing.** The game-over screen names who fell and shows your run summary. You can post
it to the online leaderboard, then play again.

| Tunable | Value | File |
|---|---|---|
| First round length | 15s | `autoload/systems/DifficultySystem.gd` (`first_round_time`) |
| Seconds added per round | 1s | same (`round_time_growth`) |
| Longest round | 25s | same (`round_time_max`) |
| Mana top-up between rounds | 50% of max | same (`round_start_mana_refill`) |

## 4. Schools and builds

**Schools [Decided].** Pick one at the start of a run. It decides your first spell and
which spells you'll be offered most.

| School | Starter | Plays like | File |
|---|---|---|---|
| Mending | Heal | Direct heals. Big numbers, right now. React to every hit. | `resources/specs/mending.tres` |
| Bloom | Renew | Heals over time. Plant early, reap later. Plan ahead. | `resources/specs/bloom.tres` |
| Ward | Shield | Shields. Stop damage before it lands. Read what's coming. | `resources/specs/ward.tres` |

Some spells belong to **Any school**: every school sees them as a home spell.

**Picks.** After round 1, then after rounds 5, 10, 15 …, choose 1 of 3 cards. The first pick
comes early so nobody plays five rounds with a single spell. You pick with the mouse or keys 1–3.

How the 3 offers are chosen (all of it is settings in `autoload/systems/DraftSystem.gd`):
- **One card from another school** whenever one is available [Decided]. Splashing is where
  creative builds come from.
- The rest favour **your school** (×3 weight), then Any-school spells (×1.5), then
  rank-ups (×2).
- **At least one card combos with something you own,** when that's possible. A card that
  combos says so ("Combos with your …").
- **Combo spells and most passives only appear once you own the tag they react to.** For
  example, Overgrowth needs a Heal-over-Time spell.
- You're never offered a spell you already own (only its next rank).

**Two kinds of slot [Decided].**
- **5 spells you cast,** on keys Q, W, E, R, T.
- **3 passive slots** in a gold tray next to the spell bar. Passives work on their own.
  Keystones will share these slots (Phase E), so a keystone costs you a passive.

**Ranks, not duplicates [Decided].** Lesser/normal/greater versions are one spell with ranks.
A rank-up is a pick option and replaces the lower rank in the same slot, so "go deeper or
go wider?" is a real choice. Ranks today: Heal → Heal II → Heal III, Renew → Rejuvenation,
Shield → Shield II.

**Build complete [Decided].** When all 5 spell slots and 3 passive slots are full and no
rank-ups are left, Pythio says the kit is complete. From then on the run is about how far
you can take it.

| Tunable | Value | File |
|---|---|---|
| First pick after round | 1 | `DraftSystem.gd` (`first_pick_after_round`) |
| Then a pick every | 5 rounds | same (`pick_every`) |
| Cards offered | 3 | same (`offer_count`) |
| Cards from another school | 1 | same (`off_school_offers`) |
| Spell slots / passive slots | 5 / 3 | same (`spellbook_cap`, `passive_cap`) |
| Weight: own school / any school / rank-up | 3 / 1.5 / 2 | same |
| A spell's own offer weight | 1 (each spell) | `resources/spells/<spell>.tres` (`offer_weight`) |

> ⚠ **Pacing concern (open question 1):** a build needs 7 picks to fill its slots (up to 11
> with rank-ups), so it completes around rounds 30–50. A typical run today ends around
> rounds 6–8, after only 2 picks.

## 5. Spells and tags, and how combos work

**Tags [Decided].** Spell text names plain-language **tags** (Balatro-style), shown as coloured
bold words. The same tags decide what combos with what. There are no fixed spell pairs, so a
new spell automatically combines with everything that shares its tag.

| Tag | Meaning | Spells with it today |
|---|---|---|
| **Direct** | An instant chunk of healing | Heal (I–III), Flash Heal, Binding Heal, Chain Heal, Mend Wounds, Spirit Surge |
| **Heal-over-Time** | Heals a bit every second | Renew / Rejuvenation, Healing Plague, Mend Wounds |
| **Shield** | Absorbs damage before health | Shield (I–II), Guardian Ward |
| **Delayed** | Heals later | Lifebloom |
| **Multi-target** | Also heals other fighters | Binding Heal, Chain Heal, Healing Plague |
| **Cleanse** | Removes a debuff | Planned for Phase D (Cleanse, Purify) |

Tag names and colours live in `resources/spells/SpellTags.gd`.

**What reacts to tags (the combos):**

| Reacts to | Spell or passive | What happens |
|---|---|---|
| Heal-over-Time | Overgrowth (spell) | Extends every heal-over-time on the fighter by 5s |
| Heal-over-Time | Aura of Mending (passive) | Each heal-over-time tick also heals the fighters on each side for 30% |
| Direct | Echo Healing (spell) | For 8s, direct heals on that fighter repeat at 50%, 2s later |
| Direct | Seraphic Blessing (passive) | Direct heals on a fighter below 40% health heal 30% more |
| Shield | Spirit Surge (spell) | Consumes the fighter's shields and heals for 150% of what was left |
| Shield | Vital Bond (passive) | When a shield breaks, the fighters on each side get a 10 shield |
| Shield | Bulwark (passive) | Shields stack at full strength and absorb 15% more |
| Overheal | Overflow, Mana Conduit (passives) | Overhealing becomes a shield, or mana |

**Readable combos [Decided].**
- **Before:** a spell button **glows gold** when casting it on the fighter under your mouse
  would fire a combo (and you can afford it). That's the WoW proc-glow idea.
- **When it fires:** gold text and a gold flash on the fighter, and sometimes a Pythio
  quip. When a passive fires, its slot in the tray pulses gold.

**Spells by school.** The full list with real numbers is in **`docs/spells.md`**. Each
spell's numbers live in its own file, `resources/spells/<spell>.tres`. Card text is
generated from those numbers, so it always matches.

| School | Spells you cast | Passives |
|---|---|---|
| Mending | Heal (I–III), Flash Heal, Binding Heal, Echo Healing, Guardian Angel | Seraphic Blessing, Overflow |
| Bloom | Renew → Rejuvenation, Lifebloom, Healing Plague, Overgrowth | Aura of Mending |
| Ward | Shield (I–II), Guardian Ward, Spirit Surge, Divine Protection, Time Stop | Bulwark, Vital Bond |
| Any school | Chain Heal, Mend Wounds, Divine Channel | Mana Conduit, Second Wind |

**Casting.** Each spell has a mana cost, a cast time (0 = instant) and sometimes a
cooldown. You can only cast one thing at a time. A round ending cancels a cast in progress.

**[Proposed] Gaps in the synergy web:**
- Nothing reacts to **Delayed** or **Multi-target** yet. One payoff each (for example a
  passive that makes Delayed heals land bigger on low fighters, or one that makes
  Multi-target heals also tick a small heal-over-time) would make those tags matter.
- Guardian Angel, Divine Protection, Time Stop and Divine Channel have no tags, so they sit
  outside the combo web. That's fine for emergency buttons, but a "Protection" tag (with
  one payoff) would bring Ward's defensive spells into it.

## 6. Passives, battlefield rules and their mirrors

**Battlefield rules [Decided].** Everyone plays by a few rules that punish sloppy play.
They're always listed top right ("BATTLEFIELD RULES"), with a tooltip for each.

**Mirrored passives [Decided].** Some passives cancel a rule and flip it in your favour.
Penalties and rewards are the same kind of thing with the sign flipped. When a rule is
cancelled, the rules panel shows it struck through, with the passive's name in gold.

| Rule (everyone) | What it does | Mirror passive | What the mirror does |
|---|---|---|---|
| Diminishing shields | A second shield on a fighter who already has one absorbs 50% less | Bulwark (Ward) | Shields stack at full strength and absorb 15% more |
| Exhaustion | Run your mana dry (too little for any spell) and it refills at half speed for 4s | Second Wind (Any) | Running dry restores 30 mana instead (once every 20s) |
| Saturation | Overheal a fighter by 8+ and your next heal on them is 30% weaker for 3s (heal-over-time ticks never trigger it) | Overflow (Mending) | 50% of overheal becomes a shield (up to 20, for 5s) |

Saturation is soft on purpose [Decided]. A hard "can't be healed" rule would punish
heals-over-time, Chain Heal and Aura of Mending, and would fight Mana Conduit.

**Other passives** (no rule to cancel): Aura of Mending, Seraphic Blessing, Vital Bond,
Mana Conduit. See the combo table in section 5.

**One system [Decided].** Rules, passives, future keystones and future debuffs are all the
same kind of thing (a `PassiveRule`), so anything one can do, the others can too.

| Tunable | Value | File |
|---|---|---|
| Diminishing shields: second shield strength | 50% | `resources/rules/diminishing_shields.tres` |
| Exhaustion: regen speed / how long | 50% / 4s | `resources/rules/exhaustion.tres` |
| Saturation: overheal needed / weaker by / how long | 8 / 30% / 3s | `resources/rules/saturation.tres` |
| Bulwark, Second Wind, Overflow and the other passives | see section 5 | `resources/spells/<passive>.tres` |

## 7. Bandages

A panic button on its own resource, separate from mana [Decided].
- **Space** while hovering a fighter (or on the last one you clicked) channels a heal.
  You can't cast while you're bandaging.
- The counter sits by the mana bar. Charges come back slowly between rounds.
- Bandages don't count as a spell or carry a tag. Combos don't react to them.
- Owner note (after Phase C): fine for now; maybe later a universal spell, or a shop
  consumable if a shop arrives.

| Tunable | Value | File |
|---|---|---|
| Healing per bandage | 40 | `autoload/systems/BandageSystem.gd` (`heal_total`) |
| Channel time | 2.5s | same (`channel_time`) |
| Charges at start / max | 3 / 3 | same (`start_charges`, `max_charges`) |
| Gain a charge every | 2 rounds cleared | same (`gain_every_rounds`) |

## 8. Difficulty and scaling

**Target [Decided].** A new player's first deaths come around rounds 6–8, after they've seen
at least two picks and a combo. Phase C measured this with the balance bot: first deaths
around rounds 6–7. Owner: reaching the first Baron is fairly easy, and it gets harder from there.

**What grows each round** (all keep growing forever unless capped):
- **Party size:** 4 fighters in round 1, one more every 2 rounds, up to 8 [Decided].
- **Fighter health:** +10% per round.
- **Steady damage** and **burst size** grow every round. The first three rounds are
  softened while you have only one or two spells.
- **Mana:** your max pool and your regen grow a little each round, so long runs aren't starved.
- **The Baron** gets tougher each visit (section 9).

**Fighters.** Each fighter has an armour type, which decides their health and how much
damage they take. Half of all fighters are light.

| Armour | Character art | Base health | Damage taken | Chance |
|---|---|---|---|---|
| Heavy | Heavy Knight | 100 | ×0.8 | 15% |
| Medium | Desperate Mercenary | 75 | ×1.1 | 35% |
| Light | Cursed Rogue / Injured Adventurer | 50 | ×1.35 | 50% |

**Bursts.** Every 5s one random fighter (never the Baron) gets a red "INCOMING" warning, and
the hit lands 1.5s later. Shields absorb it first [Decided: bursts always land after their warning].

| Tunable | Value | File |
|---|---|---|
| Steady damage per second | 2.6, +0.35 per round | `DifficultySystem.gd` (`base_dps`, `dps_growth`) |
| Burst hit | 18, +1.5 per round | same (`burst_damage_base`, `burst_damage_growth`) |
| Burst every / warning time | 5s / 1.5s | same (`burst_interval`, `burst_telegraph_time`) |
| Early rounds 1, 2, 3 damage | 60%, 75%, 90% | same (`early_damage_scale`) |
| Damage taken by armour | heavy 0.8, medium 1.1, light 1.35 | same (`armor_dps_multipliers`) |
| Max mana | 100, +8 per round | same (`max_mana_base`, `max_mana_growth`) |
| Mana regen per second | 4, +0.25 per round | same (`regen_rate_base`, `regen_growth`) |
| Party size | 4, +1 every 2 rounds, max 8 | `ContractGenerator.gd` (`party_start`, `party_growth_every`, `party_max`) |
| Fighter health | heavy 100, medium 75, light 50; +10% per round | same (`armor_base_hp`, `hp_growth_per_round`) |
| Armour chances | light 50%, medium 35%, heavy 15% | same (`armor_weights`) |

**What that adds up to** (worked out from the table above; damage is before armour):

| Round | Length | Fighters | Steady damage/s | Burst | Health ×  | Max mana | Regen/s |
|---|---|---|---|---|---|---|---|
| 1 | 15s | 4 | 1.6 | 11 | 1.0 | 100 | 4.0 |
| 5 | 19s | 6 | 4.0 | 24 | 1.4 | 132 | 5.0 |
| 10 | 24s | 8 | 5.8 | 32 | 1.9 | 172 | 6.3 |
| 20 | 25s | 8 | 9.3 | 47 | 2.9 | 252 | 8.8 |

## 9. The Crimson Baron

**[Decided]** The Baron returns on every 5th round (5, 10, 15 …), tougher each time. He's
your *patient*, not an enemy: he arrives badly hurt, with two guards (ordinary heavy
fighters), so the fight is still triage, not one big health bar. He has his own Next-party
card ("The Crimson Baron sends for you"). Random bursts never target him; his hits come
from the fight's phases.

**Three phases,** each announced with a red banner and a hint:

| Phase | Starts at | What happens | Answer |
|---|---|---|---|
| 1. The wound reopens | round start | Steady bleeding (1.2% of his health per second) | Heal faster than he bleeds |
| 2. Assassins in the rafters | 40% of the round | A warned strike (9% of his health) every 3.5s, with 1.5s warning | Shield or top him up between strikes |
| 3. The execution | 75% of the round | One huge hit (22%) after a 3s warning; bleeding rises to 2%/s | Shield him, protect him, or top him up |

| Tunable | Value | File |
|---|---|---|
| Health, first visit / extra per visit | 1200 / +600 | `ContractGenerator.gd` (`boss_base_hp`, `boss_hp_per_appearance`) |
| Starts at | 55% health | `autoload/systems/BossDirector.gd` (`start_health`) |
| Guards | 2 | same (`guards`) |
| Phase 2 / 3 start | 40% / 75% of the round | same (`phase_2_at`, `phase_3_at`) |
| Bleed, phases 1–2 / phase 3 | 1.2% / 2% of his health per second | same (`bleed_per_second`, `bleed_per_second_phase_3`) |
| Assassin strike / every / warning | 9% / 3.5s / 1.5s | same (`assassin_hit`, `assassin_every`, `assassin_warning`) |
| Execution hit / warning | 22% / 3s | same (`execution_hit`, `execution_warning`) |
| Harder each return visit | +15% | same (`per_visit`) |
| Which rounds | every 5th | `DifficultySystem.gd` (`boss_every`) |

## 10. Scoring and the leaderboard

**Score [Decided].** Rounds survived first, then **effective healing** as the tie-break.
- **Effective healing** = health actually restored (overheal doesn't count) + damage
  absorbed by shields + damage prevented by protection. It can't be more than the damage
  the party took, so it mostly tracks survival.
- **The run summary** (game over) also shows the skill stats: overheal %, damage mitigated,
  spells cast, combos fired and bandages used.

**Leaderboard [Decided].**
- Online at marz.gg. It shows the top 10. You type a name and post at game over.
- **Boards:** a new board starts only when scoring changes. Older boards stay viewable
  with ◀ ▶ so friends' scores are never lost. Today: "Phase C onward" (rounds, then
  healing) and "Builds 1–33" (the older scoring).
- **Debug runs can't be posted.** That includes god mode and anything from the F1 panel.
- **Your best on this device** shows on the start screen.

Files: `autoload/systems/RunStats.gd` (the stats), `autoload/systems/Leaderboard.gd` (the
game side), `web/leaderboard_godot.php` (the server; new boards are added here).

## 11. Controls and UI

**Controls**

| Action | Input |
|---|---|
| Cast a spell | Hover a fighter, press Q / W / E / R / T. With nothing hovered, it goes to the last fighter you clicked. |
| Cast by mouse | Click a spell button, then click a fighter |
| Bandage | Space while hovering a fighter (during a round) |
| Ready on the Next party screen | Space or Enter |
| Choose a pick card | Click, or keys 1–3 |
| Pause menu (Resume / Restart run / Quit to title) | Escape (during a run) |
| Debug panel | F1 or \` |

**Combat screen**
- **Top:** round number and timer (centre); the party size (left); battlefield rules (right).
- **Middle:** the fighters in one row. Each has a name, a health bar, an armour label, a
  shield bubble, a heal-over-time ring and status icons. The "INCOMING" warning shows above.
- **Bottom:** Pythio and his speech bubble (left); the 5 spell buttons with key, cost and
  cooldown; the passive tray; a build summary above the bar; the mana bar, cast bar and
  bandage counter.
- **Floating numbers** for heals, shields and combos (gold).

**Between rounds:** the school pick, spell picks (3 cards with tags, cost and "Combos with
your …" hints) and the Next party screen.

Main files: `scenes/game.gd` (the screen), `ui/CardChoicePanel.gd` (pick cards),
`ui/PartyChoicePanel.tscn` + `scenes/PartyChoicePanel.gd` (Next party), `ui/PauseMenu.gd`,
`ui/DebugPanel.gd`, `entities/Target.gd` (a fighter). Pythio's quips are at the top of `scenes/game.gd`.

**[Decided, backlog]** Click-casting with mouse buttons and modifier keys (the web game's
input model) is parked.

## 12. Planned features (by phase)

The roadmap has the details and issue numbers. Phases A, B and C are done and live.

**Phase D: Debuffs and cleanses [Decided]**
- From round 6, debuffs that each need a different answer:
  - **Poison:** stacking damage over time → Cleanse.
  - **Hex:** −50% healing taken → Purify.
  - **Bleed:** ends when the fighter is healed above ~80%, or bandaged.
  - Maybe **Doom** later.
- **Cleanse and Purify** (ranks of one spell) with a new **Cleanse** tag. The round-5 pick
  always offers a cleanse, so a run can't be lost to bad luck.
- Debuffs use the same rule system as passives (a debuff is a buff with the sign flipped).

**Phase E: Keystones [Decided]**
- Every 10 rounds, a rule-changing pick (1 of 3), built from the mirrored battlefield
  rules. Keystones take a passive slot, so a keystone costs you a passive. Capped.

**Phase F: Readability and feel [Decided]**
- Basic sound: casts, combos, bursts, death.
- Swap in high-res art as it's made (`docs/art.md`).
- Mana bar off gold, so gold only ever means combos (decided 2026-10-22).

**Phase G: Words, names and flair [Decided, owner-led]**
- Marz goes through every on-screen line: fonts, spell names, descriptions, flavour.
  Claude exports every line into one editable list, then applies the edits in one PR.

## 13. Parked ideas

Parked on purpose [Decided]. Don't build these without Marz's OK.
- **Duo spells** (#38), **rerolls** for picks (#39), **skill tree / meta-progression** (#40).
- **Pet and positional spells** (#41): Decoy, Healing Spirit, Soulbond, Hallowed Ground.
- **Raid mode** (#54): 10–25 fighters with compact raid frames.
- **Contract choice with reward and threat previews** (#55). Today there's one Next party
  screen, because two near-identical contracts were a false choice. Contracts come back
  only when there's something real to choose between.
- **Gold and a shop.** Bandages could become a shop item.
- **Click-casting** with mouse button + modifier bindings.
- Better scoring, difficulty modes, achievements.
- Spells from the original list not in the game: Harmonize, Tranquility, Fountain of Light,
  Aegis of Light, Revitalize, Shadow Strike (rename first: the name doesn't match the effect).

## 14. Open questions for Marz

1. **Pick pacing.** A typical run sees 2 picks, and a complete build arrives around rounds
   30–50. Build-crafting (the roguelite half of the pitch) barely gets to show up. Phase D's
   guaranteed cleanse at the round-5 pick would make one of those two picks forced.
   **[Proposed]** Pick one, or mix:
   - picks every 3 rounds (after 1, 3, 6, 9 …);
   - a bonus pick for beating the Baron;
   - make Cleanse a basic ability every school has (like bandages), so the round-5 pick
     stays free.
   Decide after the Phase D playtest.
2. **Keystones and spell picks at round 10, 20 …** Both land on the same rounds. Do you get
   two picks in a row, or does the keystone replace the spell pick? And when all 3 passive
   slots are full, does taking a keystone mean dropping a passive? **[Proposed]** Two picks
   in a row (the keystone after the spell). A keystone with full slots asks which passive
   to drop. Losing a passive should hurt; that's the point.
3. **The long game.** Damage, health and mana all grow in straight lines forever, and the
   party caps at 8 by round 9. Past round ~15, what makes round 25 feel different from
   round 15, other than bigger numbers? **[Proposed]** "Escalating chaos" should come from
   new kinds of threat (debuffs, then mixed patterns and battlefield events) more than from
   bigger numbers. Revisit after Phase D.
4. **Tags with no payoff.** Delayed and Multi-target have nothing that reacts to them, and
   Ward's defensive spells have no tag (section 5). Add payoffs now, or wait for Phase G or a
   later spell batch?

## Known differences between docs and code (2026-10-22)

Listed so nobody "fixes" the wrong side.
- **Combo-ready glow:** `design-direction.md` says the fighter's frame glows. What's built
  is the spell button glowing. **The built version is right.**
- **Contracts:** `design-direction.md` says contracts show reward and threat. Phase C
  replaced them with one Next party screen and parked the choice (#55). **Next party is right.**
- **Gold:** `art.md` said gold = mana. **Gold = combos only** (decided 2026-10-22). The
  mana bar changes colour in Phase F.
- **Leftover code (does nothing, safe to clean up):** an old points score (round × 100)
  and a "Contract fulfilled, all rounds survived" ending that endless mode never reaches
  (`GameManager.gd`, `scenes/game.gd`); contracts' hidden gold, risk and burst-threat
  numbers (`ContractGenerator.gd`); the old two-contract layout in the Next party panel.

## Changelog

| Date | Who | Change |
|---|---|---|
| 2026-10-22 | Claude (for Marz) | First version, built from the live code and the docs after Phase C. Marz decided: one Next party screen (contract choice parked), gold = combos only, this doc wins over the other design docs, and pick pacing stays an open question. |
