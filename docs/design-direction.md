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
  capped (5 spells). There should be a moment where the build is complete and the run
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
