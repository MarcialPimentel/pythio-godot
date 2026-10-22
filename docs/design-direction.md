# Pythio: design direction (2026-10-21)

The owner's decisions from the 2026-10-21 design review, and the reasoning behind them.
These win over `docs/design.md` (the original web game) where they disagree.

## The feel we're after
Real-time "plate spinning" healing like WoW healer raid frames: many short decisions,
reading incoming damage, prioritizing, combining spells on a target. High APM comes from
short, frequent decisions, not long casts. Most spells should be instant to ~1.5s; long
casts are deliberate gambles (Divine Channel: stop healing for 5s to get mana back).

## Structure
- **Endless.** Rounds continue until a fighter dies. Rounds stay under 30s (start ~15s,
  grow to a ~25s cap) so the pace stays frantic. The Crimson Baron returns every 5th round.
- **Specialization at the start:** Mending (Heal), Bloom (Renew), Ward (Shield).
- **A new spell every 5 rounds,** 1 of 3, school-weighted with one off-school card,
  capped (5 spells). As built: the first pick comes after round 1 (so nobody plays five
  rounds with a single spell), then after rounds 5, 10, 15 …; at least one offer combos
  with your spellbook when possible. All of it is `DraftSystem` settings. There should be a moment where the build is complete and the run
  becomes about how far you can take it.
- **Keystones every 10 rounds,** rule-changing, capped.
- **Contracts are repurposed** to show what you'll get (reward) and what you'll face
  (threat) — the choice is "the fight my build handles, or the harder one with the reward
  I need."

## Synergies
- **Plain-language tags** like Balatro: spell text names tags (**Direct**,
  **Heal-over-Time**, **Shield**, **Cleanse**, **Delayed**, **Multi-target**), and the
  same tags decide what interacts. No fixed spell pairs.
- Every spell is good on its own and better with friends — that's how "no bad choice"
  holds up.
- Combos must be readable at a glance during play (gold glow on the fighter's frame when a
  combo is ready; gold flash and a quip when it fires).

## Spells: what the 2026-10-21 review found
Efficiency of the original spell list (`spells.json` from the web game):

| Spell | HP per mana | HP per second of cast | Problem |
|---|---|---|---|
| Flash Heal | 2.0 | 40 | fastest *and* most efficient direct heal → dominates |
| Heal | 1.5 | 12 | strictly worse than Flash Heal |
| Greater Heal | 1.67 | 17 | strictly worse than Flash Heal |
| Mend Wounds | 2.5 | — | beats every direct heal and also cleanses |
| Renew → Rejuvenation | 2.5 → 4.0 | — | HoTs dominate efficiency |
| Lifebloom | 5.0 | — | best in the game (if the round lasts long enough) |

**Rule from now on: fast, efficient, big — pick two.**

- **Ranks replace duplicates:** Lesser Heal / Heal / Greater Heal → Heal I/II/III;
  Renew → Rejuvenation; Cleanse → Purify. Rank-ups appear as spell-pick options.
- **School sketch (to refine in #22/#27):**
  - Mending: Heal (ranks), Flash Heal, Binding Heal, Echo Healing, Guardian Angel
  - Bloom: Renew (ranks), Lifebloom, Overgrowth, Healing Plague, Harmonize
  - Ward: Shield, Guardian Ward, Divine Protection, Time Stop, a shield-break payoff
  - Any school: Chain Heal, Mend Wounds, Cleanse (ranks), Divine Channel, Mana Conduit
- **Needs work before use:** Healing Plague (numbers ambiguous, possibly broken), Vital
  Bond (weak, and random targeting fights triage), Seraphic Blessing (a plain stat
  boost — better as a keystone or tree node), Shadow Strike (name doesn't match the
  effect; rename only with owner's OK).
- **Parked:** Decoy, Healing Spirit, Soulbond (need pets/clones/positioning).

## Systems approach
Four building blocks; everything else is data (`.tres`), not new code:
- **Effect** — heal, heal-over-time, shield, cleanse, delayed heal, damage reduction,
  prevent death. A spell = cost + cast time + targeting + tags + a list of effects.
- **Status** — something living on a fighter (HoT, shield, DoT) that announces events
  (tick, absorb, break, expire).
- **Trigger** — "when event X happens to something tagged Y, do Z." Combos, passives,
  keystones and contract modifiers are all triggers.
- **Modifier** — a number change ("+20% Heal-over-Time duration").

Pick offers (school weights, prerequisites, caps, cadence) and encounters (damage
patterns) are data too.

## Parked on purpose
Duo spells · rerolls · skill tree / meta-progression · pets and positional spells.

## After the Phase B playtest (2026-10-21, evening)
Owner feedback: pleased overall; hard (round 4 so far — fine, but first deaths should come
after the build starts to click); passives should leave the spell bar; two near-identical
contracts are a false choice; spells should flash when a combo is ready.

- **Difficulty curve:** a new player's first deaths around rounds 6–8, so they see at least
  two picks and a combo. Main lever: one more fighter every 2 rounds instead of every round.
- **Slots:** 5 spells you cast (Q–T) + **3 passive slots** in a separate tray, shared with
  keystones. A keystone costs you a passive — that keeps "build complete" meaningful.
- **One "next party" screen** instead of two contracts (a non-choice erodes trust in every
  other choice). Real contract choices come back when there's something to choose (backlog).
- **Combo-ready glow:** the readability answer for a high-APM game — the spell to press
  glows (WoW proc-glow style), worked out from tags.
- **Bandages:** a panic button on a separate resource from mana — Space on a hovered
  fighter, channelled, 3 charges max, +1 every 2 rounds.
- **Battlefield rules ↔ mirrored passives.** Penalties and rewards are the same kind of
  rule with the sign flipped, built on the passive-rule system:

  | Rule (everyone) | Mirror (a passive or keystone flips it) |
  |---|---|
  | Diminishing shields: a 2nd shield on a fighter absorbs less | Bulwark: shields stack fully |
  | Exhaustion: hitting 0 mana slows regen for a few seconds | Second Wind: hitting 0 mana restores some |
  | Saturation (soft): overhealing makes the next heal on that fighter weaker briefly | Overflow: overheal becomes a small shield |

  The overheal rule is deliberately soft: a hard "can't be healed" would punish HoTs,
  Chain Heal and Aura of Mending and fight Mana Conduit.
- **Score:** rounds survived, then **effective healing** (health restored without overheal +
  damage absorbed by shields + damage prevented). Effective healing can't exceed the damage
  taken, so it mostly tracks survival — it's the tie-break; the run summary shows the
  skill stats (overheal %, mitigated). New scores go on a new
  board; each earlier board is kept and browsable by build with arrows (owner: friends'
  scores must stay visible).
- **Later (Phase D):** debuffs from round 6, each with a different answer — Poison →
  Cleanse, Hex (−50% healing) → Purify, Bleed → heal above ~80% or bandage. The round-5
  pick always offers a cleanse, so a run can't be lost to bad luck.
- **Backlog:** raid mode (10–25 fighters, compact raid frames, groups).

