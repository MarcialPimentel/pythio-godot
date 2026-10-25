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

**The two reasons to play again [Decided 2026-10-22].** The core of the game is the spells
you get and how they combine. A run should serve both of these players:
- **"How far can I get with the spells I got?"** You ride the luck of the offers and adapt.
- **"I want to master a build I like."** You steer toward a build and keep refining it.

That means **a big pool of spells** (lots to discover, runs that differ) and **enough steering**
(school, tag-weighted offers, swaps) that a favourite build can be found again. The tag
system has to make a new spell easy to add: numbers and effects, not new code.

**What each layer is for [Decided 2026-10-22]:**
- **Combos are the bread and butter:** small, frequent, every few seconds.
- **Passives are the big moments** that make a build pop off: rare, one after each Baron
  [Decided 2026-10-25: "keystones" were the same thing as passives, so they were folded in].

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
  heals-over-time and Chain Heal ↔ party-wide damage; Cleanse ↔ debuffs (Phase F);
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
- **Pythio's story [Decided 2026-10-24]:** he's down on his luck *because* he once failed to
  keep a party alive. Every run is him taking work again and trying not to lose another one,
  which is why a death ends the run, and why the roguelite loop fits. The title screen shows
  him beaten down (today the hurt pose; later, a beggar by the side of the road).
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
  move to another colour in Phase G (see Planned features).
- **Fonts:** Pirata One (titles), Oswald (UI), Special Elite (Pythio's speech), DejaVu
  (symbols). Files: `assets/fonts/`. The Phase H pass may change these.
- **Art:** stand-ins cut from a concept sheet. The style guide, file names and prompt pack
  are in `docs/art.md`.

## 3. The core loop

**First time on the job [Decided 2026-10-24].** The first time someone presses Take the Job on
a device, the game asks "First time on the job?" (once per device, whatever the answer).
**Yes** starts a practice round: one Heavy Knight, all three starting spells (Heal, Renew,
Shield), no timer, and four prompts (hover and press Q for Heal · cast time and mana · W for
Renew · a warned INCOMING hit, E for Shield). Then free practice with random hits for as long
as the player likes; the real run starts only when they press **Start the real job**. The
knight can't die and nothing counts toward stats or the leaderboard. **No** goes straight to
the run. Script: `scenes/practice.gd`.

**Run start.** Pick a school (Mending, Bloom or Ward). You start with that school's one spell.
**Run start.** **Choose your spell:** Heal, Renew or Shield. That's your first spell.

**Each round:**
1. **Next party screen:** shows who you'll heal (how many fighters, which kinds, which
   armour). Press Ready (Space). On Baron rounds the screen says "The Crimson Baron sends for you".
2. **The round:** a timer counts down. Every fighter takes steady damage. Every few seconds
   one fighter gets a **burst warning** (red ring, "INCOMING"), then takes a big hit. You
   heal, shield and protect with spells (mana) and bandages (charges).
3. **Survive the timer** and the round is cleared. **Any fighter dies** and the run is over.
   A cleared round shows **"Job finished"** for a moment (Pythio quips; clicks and keys do
   nothing), then the next screen opens. Pick and Next party screens ignore input for their
   first half second, so a click left over from the round can't pick a card or start the
   next round [Decided 2026-10-24, after watching a new player].
4. **Between rounds:** after round 1 and then every other round (3, 7, 9 …), you pick a
   new **spell** (1 of 3), or skip. After each **Baron** (rounds 5, 10, 15 …) you pick a
   **passive** instead ("The Baron's bounty"). Your mana carries over and tops up by half your max pool. Cooldowns
   reset. A new party comes in at full health.

**Endless [Decided].** Rounds never stop until someone dies. Your score is how far you got.

**Round length [Decided: stay under 30s].** Round 1 lasts 15s, and each round adds 1s up to
a 25s cap. The pace stays frantic. In the **last 5 seconds** the timer flashes and pops on
each second, so the finish line reads at a glance [Decided 2026-10-24].

**Losing.** The game-over screen names who fell and shows your run summary. You can post
it to the online leaderboard, then play again.

| Tunable | Value | File |
|---|---|---|
| First round length | 15s | `autoload/systems/DifficultySystem.gd` (`first_round_time`) |
| Seconds added per round | 1s | same (`round_time_growth`) |
| Longest round | 25s | same (`round_time_max`) |
| Mana top-up between rounds | 50% of max | same (`round_start_mana_refill`) |
| "Job finished" hold | 1.6s | same (`job_finished_time`) |
| Final countdown (timer flashes and pops each second) | last 5s | same (`final_countdown_time`) |
| Pick / Next party screens ignore input for | 0.5s | same (`screen_input_guard`) |

## 4. First spell, picks and builds (schools are hidden)

**Your first spell, and the schools underneath [Decided 2026-10-24].** The player never
sees the word "school". The run starts with **Choose your spell** (Heal, Renew or Shield),
and the cards read like any spell card. Underneath, each starter belongs to a school
(Mending, Bloom, Ward), and the school still decides which spells you're offered most.
[Proposed by Claude, built 2026-10-24] Keep that hidden weighting: it's what lets a
"master a build" player find their build again. Turning it off is one setting (school
weights in `DraftSystem.gd`).

| School (hidden) | Starter | Plays like | File |
|---|---|---|---|
| Mending | Heal | Direct heals. Big numbers, right now. React to every hit. | `resources/specs/mending.tres` |
| Bloom | Renew | Heals over time. Plant early, reap later. Plan ahead. | `resources/specs/bloom.tres` |
| Ward | Shield | Shields. Stop damage before it lands. Read what's coming. | `resources/specs/ward.tres` |

Some spells belong to **Any school**: every school sees them as a home spell. No card,
badge or HUD line names a school (the old "OTHER SCHOOL" badge and the school name above
the spell bar are gone).

**Picks: spells from picks, passives from the Baron [Decided 2026-10-25, Phase E].**
- **Spell picks:** after round 1, then every other round (3, 7, 9, 11 …), choose 1 of 3
  **spells you cast**, or Skip. Spells come early because they're the concrete, pressable
  part a new player learns first.
- **The Baron's bounty:** after each Baron (rounds 5, 10, 15 …), choose 1 of 3 **passives**.
  They lean hard toward the tags you own, so the passive makes the spells you picked better.
  No Skip. When your 3 passive slots are full, the offers are swaps, plus a card to keep
  your passives and take a spell pick instead.
- Each reward has its own beat: spells build your toolkit, passives build your engine.

| After round | You get | Spells / passives |
|---|---|---|
| 1, 3 | Spell pick | 2, then 3 / 0 |
| **5 (Baron)** | **Passive** | 3 / 1 |
| 7, 9 | Spell pick (rank-ups and swaps once the 4 keys are full) | 4 / 1 |
| **10 (Baron)** | **Passive** | 4 / 2 |
| 11, 13 | Spell pick | 4 / 2 |
| **15 (Baron)** | **Passive** | 4 / 3 |

A new player whose first deaths come around rounds 6–8 sees 3 spell picks and 1 passive.
You pick with the mouse or keys 1–4.

How the 3 offers are chosen (all of it is settings in `autoload/systems/DraftSystem.gd`):
- **Spell picks offer only spells; the Baron's bounty offers only passives.**
- **One card from another school** on spell picks, whenever one is available [Decided]. Splashing is where
  creative builds come from.
- The rest favour **your school** (×3 weight), then Any-school spells (×1.5), then
  rank-ups (×2).
- **Offers lean toward the tags you own** [Decided 2026-10-24]: a card
  that shares or reacts to one of your tags is twice as likely, two of your tags three
  times. That keeps a big pool from burying your combo pieces, for the "master a build" player.
  The Baron's passives lean harder (×3 for one tag, ×5 for two), so they improve your spells.
- **At least one card combos with something you own,** when that's possible. A card that
  combos says so ("Combos with …").
- **Combo spells and most passives only appear once you own the tag they react to.** For
  example, Overgrowth needs a Heal-over-Time spell.
- You're never offered a spell you already own (only its next rank).

**Two kinds of slot [Decided].**
- **4 spells you cast,** on keys Q, W, E, R (was 5 until Phase D). Enough for the fast /
  efficient / big triangle plus a combo spell; every slot matters.
- **3 passive slots** in a gold tray next to the spell bar [Decided 2026-10-24: keep 3].
  Passives work on their own, and come only from beating the Baron (one per visit).

**Ranks, not duplicates [Decided].** Lesser/normal/greater versions are one spell with ranks.
A rank-up is a pick option and replaces the lower rank in the same slot, so "go deeper or
go wider?" is a real choice. Ranks today: Heal → Heal II → Heal III, Renew → Rejuvenation,
Shield → Shield II.

**When your bar is full: swap, upgrade or skip** [Decided 2026-10-24]. New spells (or, on the Baron's bounty, passives) are still offered, marked **SWAP**. Taking one asks
"Replace which spell?" (with a Back button), and the new spell takes the old one's slot and
key. Rank-ups work as before. Every spell pick has a **Skip** card: +10 max mana for the
rest of the run [Decided 2026-10-24: keep for now]. To go back to the old rule (rank-ups only, then nothing), turn off
`swap_when_full`.

**Build complete [Decided].** When all spell and passive slots are full and no rank-ups are
left, Pythio says the kit is full. Picks keep coming (as swaps), so the run is about how far
you can take it, and whether to change your build on the way.

| Tunable | Value | File |
|---|---|---|
| First pick after round | 1 | `DraftSystem.gd` (`first_pick_after_round`) |
| Then a pick every | 2 rounds | same (`pick_every`) |
| Cards offered | 3 (+ Skip on spell picks) | same (`offer_count`) |
| Passives from the Baron (off = Phase D mixed picks) | on | same (`passives_from_baron`) |
| Which rounds have a Baron | every 5th | `DifficultySystem.gd` (`boss_every`) |
| Cards from another school (spell picks) | 1 | same (`off_school_offers`) |
| Spell slots / passive slots | 4 / 3 | same (`spellbook_cap`, `passive_cap`), and `SpellSystem.gd` (`SLOTS`) |
| Weight: own school / any school / rank-up | 3 / 1.5 / 2 | same |
| Tag weighting (each owned tag shared, up to 2) | +1× spells, +2× Baron passives | same (`tag_affinity_weight`, `passive_tag_weight`) |
| Swap when full / Skip reward | on / +10 max mana | same (`swap_when_full`, `skip_bonus_max_mana`) |
| A spell's own offer weight | 1 (each spell) | `resources/spells/<spell>.tres` (`offer_weight`) |

## 5. Spells and tags, and how combos work

**Tags [Decided].** Spell text names plain-language **tags** (Balatro-style), shown as coloured
bold words. The same tags decide what combos with what. There are no fixed spell pairs, so a
new spell automatically combines with everything that shares its tag.

| Tag | Meaning | Spells with it today |
|---|---|---|
| **Direct** | An instant chunk of healing | Heal (I–III), Flash Heal, Binding Heal, Chain Heal, Mend Wounds, Spirit Surge |
| **Heal-over-Time** | Heals a bit every second | Renew / Rejuvenation, Healing Plague, Mend Wounds, Tranquility |
| **Shield** | Absorbs damage before health | Shield (I–II), Guardian Ward, Aegis of Light |
| **Delayed** | Heals later | Lifebloom, Promise of Light |
| **Multi-target** | Also heals other fighters | Binding Heal, Chain Heal, Healing Plague, Tranquility, Aegis of Light |
| **Mitigation** | Stops damage instead of healing it (named Protection until 2026-10-24) [Decided] | Divine Protection, Time Stop, Guardian Angel |
| **Cleanse** | Removes a debuff | Planned for Phase F (the basic Cleanse ability, and spells that react to it) |

Tag names and colours live in `resources/spells/SpellTags.gd`. **Rule of thumb [Proposed]:**
every tag has at least 2 spells with it and 2 that react to it (true since Phase D; the
`test_batch2.gd` census checks it).

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
| Delayed | Hasten (spell) | Your Delayed heals on the fighter land now, 25% bigger |
| Delayed | Ripening (passive) | Delayed heals on a fighter below 50% health heal 50% more |
| Multi-target | Lingering Light (passive) | Casting a Multi-target spell leaves a 3/s heal-over-time on the target for 4s |
| Multi-target | Rising Tide (passive) | Every 3rd Multi-target spell you cast gives 20 mana |
| Mitigation | Sanctuary (passive) | Casting a Mitigation spell also gives the fighter a 15 shield |
| Mitigation | Watchful Eye (passive) | Casting a Mitigation spell on a fighter below 40% heals them for 25 |
| Overheal | Overflow, Mana Conduit (passives) | Overhealing becomes a shield, or mana |
| Direct | Double Down (passive, Phase E) | Every 4th Direct heal lands twice |
| Heal-over-Time | Wildgrowth (passive, Phase E) | Casting a Heal-over-Time spell makes every heal-over-time on the party last 2s longer |
| Shield | Shatterpoint (passive, Phase E) | A breaking shield heals every fighter for 40% of what it held (up to 12) |
| Delayed | Harvest (passive, Phase E) | Delayed heals also heal your most injured fighter for 50% |
| Multi-target | Chain Reaction (passive, Phase E) | Casting a Multi-target spell also heals your most injured fighter for 15 |
| Mitigation | Bastion (passive, Phase E) | Casting a Mitigation spell gives every fighter an 8 shield |

**Readable combos [Decided].**
- **Before:** a spell button **glows gold** when casting it on the fighter under your mouse
  would fire a combo (and you can afford it). That's the WoW proc-glow idea. Only
  conditional bonuses glow (a low fighter, the 3rd cast, a shield to cash in); a bonus that
  always applies doesn't, so the glow keeps meaning "press it now".
- **When it fires:** gold text and a gold flash on the fighter, and sometimes a Pythio
  quip. When a passive fires, its slot in the tray pulses gold.

**Spells by school.** The full list with real numbers is in **`docs/spells.md`**. Each
spell's numbers live in its own file, `resources/spells/<spell>.tres`. Card text is
generated from those numbers, so it always matches.

| School | Spells you cast | Passives |
|---|---|---|
| Mending | Heal (I–III), Flash Heal, Binding Heal, Echo Healing, Guardian Angel, Promise of Light | Seraphic Blessing, Overflow, Rising Tide, Double Down |
| Bloom | Renew → Rejuvenation, Lifebloom, Healing Plague, Overgrowth, Hasten, Tranquility | Aura of Mending, Ripening, Wildgrowth, Harvest |
| Ward | Shield (I–II), Guardian Ward, Spirit Surge, Divine Protection, Time Stop, Aegis of Light | Bulwark, Vital Bond, Sanctuary, Watchful Eye, Shatterpoint, Bastion |
| Any school | Chain Heal, Mend Wounds, Divine Channel | Mana Conduit, Second Wind, Lingering Light, Chain Reaction |

43 entries in all: 21 spells you cast (with ranks), 18 passives.

**Casting.** Each spell has a mana cost, a cast time (0 = instant) and sometimes a
cooldown. **Cast time is shown first** [Decided 2026-10-24]: every spell card has a big
**INSTANT** or **1.5s CAST** badge (bone white, outside the colour language), and each spell
button shows "inst" or "1.5s" in its corner.

**Card text is one sentence [Decided 2026-10-24].** A new player should read a card in one
breath: "Heals 30, and the fighters on each side for 15." Card text is generated from the
effects (`resources/spells/effects/*.gd`, `describe()`), so this holds for new spells too. You can only cast one thing at a time. A round ending cancels a cast in progress.

**Adding a spell is data [Decided 2026-10-22: the pool should grow easily].**
- **A spell you cast** = a `.tres` file in `resources/spells/` listing its cost, cast time,
  cooldown, tags and effects (heal, heal-over-time, shield, delayed heal, protection, death
  save, extend heals-over-time, echo, consume shields, hasten delayed heals, mana). Heals
  over time and shields can target the whole party.
- **A passive** = a `.tres` file using the **generic tag trigger** (section 6): pick an event,
  the tags, an optional health condition, an action and who it hits. The card text writes itself.
- New *kinds* of effect (a new verb) still need code; new spells built from existing verbs don't.

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

**Other passives** (no rule to cancel): see the combo table in section 5.

**Passives are data: the generic tag trigger (Phase D).** Every passive is one rule read from
its file: **when** [event] happens to something tagged [tags] (optionally on a fighter below
X% health), **do** [action] to [who].

| Part | Choices |
|---|---|
| Event | a heal lands · a heal is about to land (boost it) · a heal-over-time ticks · overheal · a shield breaks · a shield is about to go on (boost it) · you cast a spell · you run your mana dry |
| Conditions | tags · below X% health · a minimum amount · ignore quiet heals or echoes · every Nth time · a cooldown |
| Action | heal · shield · mana · heal-over-time · extend heals-over-time · boost (+%) |
| Who | that fighter · the fighters on each side · your most injured fighter · every fighter |

Triggers can't set off the same kind of trigger (no endless chains). Script:
`resources/spells/passives/TagTriggerRule.gd`. The six Phase E passives use the same parts
(no new code).

**One system [Decided].** Rules, passives and future debuffs are all the
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

**Cleanse is its own plate [Decided 2026-10-22, coming in Phase F].** Healing and cleansing
stay separate identities. Every school gets **Cleanse** as a basic ability with its own key
and its own charges or cooldown, and it only removes debuffs (no heal). The bandage stays a
healing panic button. Later decisions: whether to keep the bandage, and whether passives
can improve Cleanse or the bandage. **[Proposed]** Cleanse on **F** (next to Q–R), with the
bandage staying on Space.

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

**[Decided]** The Baron returns on every 5th round (5, 10, 15 …), tougher each time.
**Beating him pays a passive** ("The Baron's bounty", Phase E, decided 2026-10-25): 1 of 3,
leaning toward your tags. Up to 3; after that the bounty offers swaps or a spell pick
instead. The boss kill is the power spike. He's
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
| Cast a spell | Hover a fighter, press Q / W / E / R. With nothing hovered, it goes to the last fighter you clicked. |
| Cast by mouse | Click a spell button, then click a fighter |
| Bandage | Space while hovering a fighter (during a round) |
| Ready on the Next party screen | Space or Enter |
| Choose a pick card | Click, or keys 1–3 (4 = Skip) |
| Back from "Replace which spell?" | The Back button, or Backspace |
| Pause menu (Resume / Restart run / Quit to title) | Escape (during a run) |
| Start the real job (end of the practice round) | The button, or Enter |
| Debug panel (+mana, skip or jump rounds, take any spell, reset build, god mode, ask "First time on the job?" again) | F1 or \` |

**Combat screen**
- **Top:** round number and timer (centre); the party size (left); battlefield rules (right).
- **Middle:** the fighters in one row. Each has a name, a health bar, an armour label, a
  shield bubble, a heal-over-time ring and status icons. Under the health bar, **every**
  heal-over-time on the fighter gets its own line with its time left ("RENEW 5.8s",
  "HEALING PLAGUE 5.5s"). Different heals-over-time stack and all heal; recasting the same
  one refreshes it. The "INCOMING" warning shows above.
- **Bottom:** Pythio and his speech bubble (left); the 4 spell buttons with key, cost, cast
  time and cooldown; the passive tray; the mana bar, cast bar and bandage counter. (The
  build summary line above the bar was removed on 2026-10-24.)
- **Floating numbers** for heals, shields and combos (gold).

**Between rounds:** Choose your spell (run start), spell picks (3 cards with cast time, cost,
tags, one sentence and "Combos with …" hints) and the Next party screen.

Main files: `scenes/game.gd` (the screen), `ui/CardChoicePanel.gd` (pick cards),
`ui/PartyChoicePanel.tscn` + `scenes/PartyChoicePanel.gd` (Next party), `ui/PauseMenu.gd`,
`ui/DebugPanel.gd`, `entities/Target.gd` (a fighter). Pythio's quips are at the top of `scenes/game.gd`.

**[Decided, backlog]** Click-casting with mouse buttons and modifier keys (the web game's
input model) is parked.

## 12. Planned features (by phase)

The roadmap has the details and issue numbers. Phases A, B and C are done and live.

Phases were reordered on 2026-10-22 so more spells and the Baron's passives come first:
they're the fun we're trying to find.

**Phase D: Faster builds and more spells ✅ built 2026-10-22** (PR for #65–#70; sections 4–6
describe it): passives as data (generic tag trigger) · picks every other round · 4 spell keys ·
swap / upgrade / skip when full · offers weighted toward your tags · debug "take any spell" ·
spell batch 2 (Mitigation tag, 4 new spells, 5 new passives). **[Decided 2026-10-24]** Marz kept all of it after the playtest.

**Phase E: Spells from picks, passives from the Baron ✅ built 2026-10-25 [Decided 2026-10-25]**
(Marz: keystones and passives were the same thing, so keystones were folded into passives.)
- Ordinary picks (after 1, 3, 7, 9 …) offer only spells; each Baron (5, 10, 15 …) pays a
  passive, 1 of 3, leaning hard toward your tags. No Skip on the Baron's bounty; with full
  passive slots it offers swaps or a spell pick instead (section 4).
- Six new "Baron-worthy" passives, one per tag, all data: Double Down, Wildgrowth,
  Shatterpoint, Harvest, Chain Reaction, Bastion (section 5). The reversed battlefield rules
  already exist as Bulwark, Second Wind and Overflow.
- Bot check: first deaths still around rounds 6–8 (average 6.8, same as before).
- Later, if wanted: passives that need a new verb (e.g. "heals-over-time tick twice as fast
  but last half as long").

**Phase F: Debuffs and cleanse [Decided]**
- From round 6, debuffs that each need a different answer:
  - **Poison:** stacking damage over time → Cleanse.
  - **Hex:** −50% healing taken → Cleanse (or a stronger cleanse: Purify could return as
    an upgrade).
  - **Bleed:** ends when the fighter is healed above ~80%, or bandaged.
  - Maybe **Doom** later.
- **Cleanse as a basic ability** every school has (section 7), with a new **Cleanse** tag
  so spells and passives can react to it.
- Debuffs use the same rule system as passives (a debuff is a buff with the sign flipped).

**Phase G: Readability and feel [Decided]**
- Basic sound: casts, combos, bursts, death.
- Swap in high-res art as it's made (`docs/art.md`).
- Mana bar off gold, so gold only ever means combos (decided 2026-10-22).

**Phase H: Words, names and flair [Decided, owner-led]**
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
- **Ranks 1–3 for every spell, and spell rarity** (#71, Marz's idea 2026-10-22): late in a
  run you might swap a rank-2 common for a rank-1 rare. Revisit after Phase D.
  [Proposed] If we do it, rarity should mean a more *unusual* effect, not just bigger
  numbers, or "rare" turns into "strictly better" and breaks the pick-two rule.
- Better scoring, difficulty modes, achievements.
- Spells from the original list not in the game: Harmonize, Tranquility, Fountain of Light,
  Aegis of Light, Revitalize, Shadow Strike (rename first: the name doesn't match the effect).

## 14. Open questions for Marz

1. **Cleanse key and the bandage's future.** Cleanse on F and the bandage on Space? Do we
   keep the bandage once Cleanse exists? Should passives be able to improve either?
2. **The long game.** Damage, health and mana all grow in straight lines forever, and the
   party caps at 8 by round 9. Past round ~15, what makes round 25 feel different from
   round 15, other than bigger numbers? **[Proposed]** "Escalating chaos" should come from
   new kinds of threat (debuffs, then mixed patterns and battlefield events) more than from
   bigger numbers. Revisit after Phase F.
3. **Party-wide spells and party size.** Tranquility and Aegis of Light get stronger the
   bigger the party. Fine now (8 max), but raid mode (#54) would need them capped or
   rescaled.

**Settled 2026-10-24 (after the Phase D playtest):** keep swap / upgrade / skip when the
bar is full; keep the Skip reward (+10 max mana) for now; keep tag-weighted offers; the
Protection tag is renamed **Mitigation**; keep all 9 new spells and passives; keep 3
passive slots for now.

**Settled 2026-10-25 (Phase E):** keystones folded into passives; spells from picks,
passives from the Baron; 3 passive slots stay.

**Settled 2026-10-22:** pick pacing (every other round); keystone timing (after each Baron;
superseded 2026-10-25); tags with no payoff (handled in spell batch 2); 4 spell keys; Cleanse separate
from the bandage.

## Known differences between docs and code (2026-10-22)

Listed so nobody "fixes" the wrong side.
- **Combo-ready glow:** `design-direction.md` says the fighter's frame glows. What's built
  is the spell button glowing. **The built version is right.**
- **Contracts:** `design-direction.md` says contracts show reward and threat. Phase C
  replaced them with one Next party screen and parked the choice (#55). **Next party is right.**
- **Gold:** `art.md` said gold = mana. **Gold = combos only** (decided 2026-10-22). The
  mana bar changes colour in Phase G.
- **Leftover code (does nothing, safe to clean up):** an old points score (round × 100)
  and a "Contract fulfilled, all rounds survived" ending that endless mode never reaches
  (`GameManager.gd`, `scenes/game.gd`); contracts' hidden gold, risk and burst-threat
  numbers (`ContractGenerator.gd`); the old two-contract layout in the Next party panel.

## Changelog

| Date | Who | Change |
|---|---|---|
| 2026-10-22 | Claude (for Marz) | First version, built from the live code and the docs after Phase C. Marz decided: one Next party screen (contract choice parked), gold = combos only, this doc wins over the other design docs, and pick pacing stays an open question. |
| 2026-10-22 | Claude (for Marz) | Marz decided: the two player fantasies; combos = bread and butter, keystones = the big moments; picks every other round; 4 spell keys (Q–R); keystones after each Baron in their own 3 slots; Cleanse as its own basic ability, separate from the bandage. Phases reordered: D faster builds and more spells, E keystones, F debuffs and cleanse, G readability, H words. Proposed: swap/upgrade/skip when the bar is full, tag-weighted offers. |
| 2026-10-24 | Claude (for Marz) | First-time practice round (Marz, after watching a new player): asked once per device after Take the Job; one knight, Heal only, three prompts, can't die, then the real run. Sections 3 and 11 updated. |
| 2026-10-25 | Claude (for Marz) | Phase E: Marz decided keystones and passives are one thing. Spell picks offer only spells; each Baron pays a passive (the Baron's bounty: no Skip, leaning to your tags; swaps or a spell pick when full). Six new data passives: Double Down, Wildgrowth, Shatterpoint, Harvest, Chain Reaction, Bastion. Sections 1, 3, 4, 5, 6, 9, 12 and 14 updated. |
| 2026-10-24 | Claude (for Marz) | Marz thought Renew and Healing Plague didn't stack: they did, but the fighter only showed the longest heal-over-time. Now every one is listed. The timer flashes and pops in the last 5 seconds. Sections 3 and 11 updated. |
| 2026-10-24 | Claude (for Marz) | Practice round teaches all three starting spells and ends in free practice until Start the real job (Marz). Pick cards use fixed-height rows so titles, costs, tags and text line up; hints read "Combos with Renew". Sections 3 and 4 updated. |
| 2026-10-24 | Claude (for Marz) | Title screen shows Pythio (head bowed) instead of the knight. Marz decided Pythio's story: he's down on his luck because he once failed a party. Section 2 updated. |
| 2026-10-24 | Claude (for Marz) | "Job finished" screen after each cleared round, and a short input guard on the pick and Next party screens (Marz, after watching a new player click through by accident). Section 3 updated. |
| 2026-10-24 | Claude (for Marz) | From watching a new player: the run starts with **Choose your spell**, and "school" is never shown (it still steers offers underneath, proposed); card text is one sentence; cast time is a big badge on cards and shows on spell buttons; the build summary above the bar is gone. Sections 3, 4, 5 and 11 updated. |
| 2026-10-24 | Claude (for Marz) | Marz settled the Phase D questions: keep swap / upgrade / skip, the Skip reward (for now), tag-weighted offers, all 9 new spells and passives, and 3 passive slots (for now). The Protection tag is now called **Mitigation**. Sections 4, 5, 12 and 14 updated. |
| 2026-10-22 | Claude (for Marz) | Phase D built: passives as data (generic tag trigger), picks every other round, 4 spell keys, swap / upgrade / skip when full, offers weighted toward your tags, debug "take any spell", spell batch 2 (Protection tag; Promise of Light, Hasten, Tranquility, Aegis of Light; Ripening, Lingering Light, Rising Tide, Sanctuary, Watchful Eye). Sections 3–6, 11, 12 and 14 updated. |
