# Pythio: spell catalog

> **The spell catalog:** every spell in the game with its real numbers, then the owner's
> original spell ideas. How spells, tags, picks, passives and rules work is in
> **`docs/game-design.md`** (sections 4–6), which wins over this file.
> The original web game's spell data is in `docs/spells-web.json`; the 2026-10-21 balance
> review is in `docs/design-direction.md`.

## Spells in the game now (after Phase C, 2026-10-22)

The game's real numbers, generated from `resources/spells/*.tres` (edit those files to change a
spell; the card text is built from them). "HP per mana" counts every point of healing/absorb
a cast can do (shields count what they absorb). When a spell changes, update its row here in
the same PR.

| Spell | School | Tags | Mana | Cast | Cooldown | What it does | HP per mana |
|---|---|---|---|---|---|---|---|
| Binding Heal | Mending | Direct, Multi-target | 18 | 1.5s | — | Heals 30. Also heals your most injured other fighter for 20. | 2.8 |
| Echo Healing | Mending | — | 12 | instant | 10s | For 8s, Direct heals on this fighter echo: 50% of each heal repeats 2s later. Offered once you own a Direct spell. | — |
| Flash Heal | Mending | Direct | 20 | instant | — | Heals 32. | 1.6 |
| Guardian Angel | Mending | — | 25 | instant | 25s | For 6s, a killing blow leaves the fighter at 1 health instead, then heals them for 30. | — |
| Heal | Mending | Direct | 10 | 1.5s | — | Heals 30. | 3.0 |
| Heal II *(rank 2)* | Mending | Direct | 13 | 1.5s | — | Heals 45. | 3.5 |
| Heal III *(rank 3)* | Mending | Direct | 16 | 1.5s | — | Heals 62. | 3.9 |
| Overflow | Mending | — | passive | — | — | Cancels Saturation: overhealing turns 50% of the overheal into a Shield (up to 20, 5s). | — |
| Seraphic Blessing | Mending | — | passive | — | — | Your Direct heals on a fighter below 40% health heal 30% more. Offered once you own a Direct spell. | — |
| Aura of Mending | Bloom | — | passive | — | — | Each time one of your Heal-over-Time effects heals, the fighters on each side are healed for 30% of it. Offered once you own a Heal-over-Time spell. | — |
| Healing Plague | Bloom | Heal-over-Time, Multi-target | 22 | 1.5s | — | Heals 24 over 6s (4 each second). Also on the fighters on each side. | 3.3 |
| Lifebloom | Bloom | Delayed | 10 | instant | — | After 6s, heals 45. | 4.5 |
| Overgrowth | Bloom | — | 10 | instant | 6s | Extends every Heal-over-Time effect on the fighter by 5s. Offered once you own a Heal-over-Time spell. | — |
| Renew | Bloom | Heal-over-Time | 12 | instant | — | Heals 40 over 8s (5 each second). | 3.3 |
| Rejuvenation *(rank 2)* | Bloom | Heal-over-Time | 16 | instant | — | Heals 64 over 8s (8 each second). | 4.0 |
| Bulwark | Ward | — | passive | — | — | Cancels Diminishing shields: your Shield effects stack at full strength and absorb 15% more. Offered once you own a Shield spell. | — |
| Divine Protection | Ward | — | 20 | instant | 12s | The fighter takes 50% less damage for 5s. | — |
| Guardian Ward | Ward | Shield | 18 | instant | — | Absorbs the next 25 damage for 6s. When it breaks or fades, heals 20. | 2.5 |
| Shield | Ward | Shield | 14 | instant | — | Absorbs the next 30 damage for 8s. | 2.1 |
| Shield II *(rank 2)* | Ward | Shield | 17 | instant | — | Absorbs the next 45 damage for 8s. | 2.6 |
| Spirit Surge | Ward | Direct | 10 | instant | 4s | Consumes the Shield effects on this fighter and heals for 150% of what they had left. Offered once you own a Shield spell. | — |
| Time Stop | Ward | — | 25 | instant | 20s | The fighter takes no damage for 2.5s. | — |
| Vital Bond | Ward | — | passive | — | — | When one of your Shield effects breaks, the fighters on each side gain a 10 Shield for 5s. Offered once you own a Shield spell. | — |
| Chain Heal | Any school | Direct, Multi-target | 26 | 2s | — | Heals 30. Also heals the fighters on each side for 15. | 2.3 |
| Divine Channel | Any school | — | 0 | 3s | 30s | Restores 50 of your mana. | — |
| Mana Conduit | Any school | — | passive | — | — | Overhealing isn't wasted: you get 20% of it back as mana. | — |
| Mend Wounds | Any school | Direct, Heal-over-Time | 16 | 1s | — | Heals 20. Then heals 15 over 5s (3 each second). | 2.2 |
| Second Wind | Any school | — | passive | — | — | Cancels Exhaustion: running your mana dry restores 30 mana instead (once every 20s). | — |

### Not in the game yet
Cleanse / Purify (Phase D) · Keystones (Phase E) · Harmonize, Decoy,
Healing Spirit, Soulbond, Hallowed Ground (pets / positioning, parked) · Shadow Strike
(name doesn't match the effect; rename first) · Vital Bond and Lifebloom follow the reworked
versions above, not the original wording below.

## Original spell ideas (owner's list)

A comprehensive list of spells categorized by their function, including basic spells, advanced spells, keystone spells, and experimental mechanics.

## Universal Pool (Basic Spells)

Starting spells available for selection (players pick 3 at game start). Designed to cover fundamental healing mechanics and provide an early game identity.

| Spell Name | Effect | Mana Cost | Cast Time | Cooldown | Notes |
|---|---|---|---|---|---|
| Heal | Restores 30 HP to a single target. | 15 | 2s | None | Standard, baseline heal. |
| Renew | Heals 5 HP/s for 10s (50 HP total). | 20 | Instant | None | Healing-over-time spell. |
| Shield | Absorbs 30 HP of damage for 5s. | 20 | Instant | 6s | Prevents incoming damage. |
| Flash Heal | Restores 40 HP instantly. | 20 | 1s | 5s | Quick but inefficient. |
| Chain Heal | Heals 30 HP to main target, 15 HP to 1 adjacent target. | 35 | 2s | 6s | Small group healing. |
| Cleanse | Removes all negative effects (DoT, debuffs) from a target. | 15 | 1s | 6s | Essential for damage mitigation. |

## Advanced Spells (Unlocked Through Progression & Talents)

(These spells are unlocked through tier upgrades, synergies, or keystone selections.)

| Spell Name | Effect | Mana Cost | Cast Time | Cooldown | Notes |
|---|---|---|---|---|---|
| Greater Heal | Restores 50 HP to a single target. | 30 | 3s | None | More powerful but slower cast. |
| Rejuvenation | Heals 10 HP/s for 10s (100 HP total). | 25 | Instant | None | Stronger Renew variant. |
| Divine Protection | Reduces damage taken by 50% for 5s. | 25 | Instant | 8s | Works like a shield but stacks with it. |
| Harmonize | Spreads 50% of healing from the primary target to all others. | 35 | 2s | 6s | AoE healing amplification. |
| Aura of Mending | Each heal has a 25% chance to heal an adjacent target for 15 HP. | Passive | None | None | Persistent effect. |
| Lifebloom | After 10s, heals 50 HP instantly. | 10 | Instant | None | Strong delayed heal. |
| Purify | Removes all negative effects and prevents reapplication for 3s. | 20 | 1s | 8s | Upgraded Cleanse. |
| Mend Wounds | Restores 25 HP instantly, then another 25 HP over 5s. | 20 | 1.5s | 5s | Burst + HoT combination. |
| Guardian Ward | Absorbs 20 HP for 6s and heals 10 HP upon expiration. | 20 | Instant | 6s | Hybrid protection & heal. |
| Divine Channel | Gain 100 mana over 5s. | 0 | 5s | 15s | No healing but solves mana issues. |
| Aegis of Light | Prevents the next 30 HP of damage to all allies. | 40 | 2s | 12s | Party-wide defensive ability. |
| Revitalize | Increases mana regeneration by +2/s for 10s. | 25 | Instant | 10s | Helps sustain healing over time. |

## Keystone Spells (Major Specialization-Defining Abilities)

(Chosen at Round 10 and Round 20. Each unlocks one additional spell and defines synergies.)

| Keystone Name | Effect | Synergies | Unlocks |
|---|---|---|---|
| Binding Heal | Heals 30 HP to target and 15 HP to the most injured target. | Heal + Binding Heal = +20% healing | Beacon of Light (Heals spread to another target at 50% efficiency) |
| Healing Plague | Inflicts a HoT (15 HP/s for 8s) that spreads to 2 targets. | Renew + Healing Plague = Duration extended by 3s | Lifebloom (Grants an instant 40 HP burst at the end of the duration) |
| Time Stop | Prevents all damage on all targets for 2s. | Shield + Time Stop = +2s shield duration | Foresight Ward (Prevents the next 40 HP of damage over 6s) |
| Shadow Strike | Converts 30% of missing HP into healing. | Flash Heal + Shadow Strike = 20% bonus healing | Umbral Drain (Transfers 25% of the healing done to another ally) |
| Seraphic Blessing | Passively grants +10% healing to all spells. | Chain Heal + Seraphic Blessing = Heals all targets hit for +10 HP | Radiant Cascade (AoE healing every 5s based on your own healing output) |
| Vital Bond | Whenever a target is healed, another random target is healed for 15 HP. | Lifebloom + Vital Bond = Extra 20 HP heal upon expiration | Shared Harmony (Healing one ally boosts the next heal by 10%) |

## Experimental & Synergy-Based Spells

(These spells interact with others to create unique effects.)

| Spell Name | Effect | Mana Cost | Cast Time | Cooldown | Notes |
|---|---|---|---|---|---|
| Overgrowth | Increases duration of all active HoTs by 5s. | 20 | Instant | 6s | Great for HoT-focused builds. |
| Echo Heal | The next single-target heal will repeat at 50% effectiveness after 3s. | 15 | Instant | 8s | Creates a delayed effect. |
| Tranquility | Restores 5 HP/s to all targets for 10s. | 50 | 2s | 12s | Large-scale AoE healing. |
| Spirit Surge | Converts shields into healing (50% of shield value). | 30 | Instant | 6s | Turns mitigation into burst healing. |
| Fountain of Light | Heals all allies for 20 HP and grants 2 mana per tick. | 40 | 3s | 10s | AoE healing + mana regeneration. |
| Guardian Angel | Prevents one target from dying for 5s. | 35 | Instant | 12s | "Last Stand" defensive spell. |
| Soulbond | Links two targets; healing one heals the other for 50% of the amount. | 25 | Instant | None | Requires positioning strategy. |
| Hallowed Ground | Increases healing received by all allies standing within the area. | 30 | Instant | 10s | Positional-based buff. |

## Final Thoughts on This Spell List

✅ Diverse Starting Spells: The universal pool provides solid fundamentals without overwhelming new players.

✅ Keystone Spells Shape Playstyle: Keystone spells define the macro-strategy of the player’s build.

✅ Synergy-Driven Choices: Players can mix and match to create powerful combo-based healing.

✅ Experimental & Advanced Mechanics: Spells like Echo Heal, Overgrowth, and Soulbond open up skill expression and build diversity.

