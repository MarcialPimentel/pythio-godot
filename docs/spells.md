# Pythio: spell catalog

> **The spell catalog:** every spell in the game with its real numbers, then the owner's
> original spell ideas. How spells, tags, picks, passives and rules work is in
> **`docs/game-design.md`** (sections 4–6), which wins over this file.
> The original web game's spell data is in `docs/spells-web.json`; the 2026-10-21 balance
> review is in `docs/design-direction.md`.

## Spells in the game now (after Phase D, 2026-10-22; card text made one sentence 2026-10-24)

The game's real numbers, generated from `resources/spells/*.tres` (edit those files to change a
spell; the card text is built from them). "HP per mana" counts every point of healing/absorb
a cast can do (shields count what they absorb). When a spell changes, update its row here in
the same PR.

| Spell | School (hidden) | Tags | Mana | Cast | Cooldown | What it does | HP per mana |
|---|---|---|---|---|---|---|---|
| Binding Heal | Mending | Direct, Multi-target | 18 | 1.5s | — | Heals 30, and your most injured other fighter for 20. | 2.8 |
| Echo Healing | Mending | — | 12 | instant | 10s | For 8s, Direct heals on this fighter echo: 50% of each heal repeats 2s later. Offered once you own a Direct spell. | — |
| Flash Heal | Mending | Direct | 20 | instant | — | Heals 32. | 1.6 |
| Guardian Angel | Mending | Mitigation | 25 | instant | 25s | For 6s, a killing blow leaves the fighter at 1 health instead, then heals them for 30. | — |
| Heal | Mending | Direct | 10 | 1.5s | — | Heals 30. | 3.0 |
| Heal II *(rank 2)* | Mending | Direct | 13 | 1.5s | — | Heals 45. | 3.5 |
| Heal III *(rank 3)* | Mending | Direct | 16 | 1.5s | — | Heals 62. | 3.9 |
| Overflow | Mending | — | passive | passive | — | Cancels Saturation: overhealing turns 50% of the overheal into a Shield (up to 20, 5s). | — |
| Promise of Light | Mending | Delayed | 14 | instant | — | After 3s, heals 40. | 2.9 |
| Rising Tide | Mending | — | passive | passive | — | When you cast a Multi-target spell, you get 20 mana (every 3rd time). Offered once you own a Multi-target spell. | — |
| Seraphic Blessing | Mending | — | passive | passive | — | Your Direct heals on a fighter below 40% health heal 30% more. Offered once you own a Direct spell. | — |
| Aura of Mending | Bloom | — | passive | passive | — | Each time one of your Heal-over-Time effects heals, the fighters on each side are healed for 30% of it. Offered once you own a Heal-over-Time spell. | — |
| Hasten | Bloom | — | 8 | instant | 8s | Your Delayed heals on the fighter land now, 25% bigger. Offered once you own a Delayed spell. | — |
| Healing Plague | Bloom | Heal-over-Time, Multi-target | 22 | 1.5s | — | Heals this fighter and the ones on each side for 24 over 6s. | 3.3 |
| Lifebloom | Bloom | Delayed | 10 | instant | — | After 6s, heals 45. | 4.5 |
| Overgrowth | Bloom | — | 10 | instant | 6s | Extends every Heal-over-Time effect on the fighter by 5s. Offered once you own a Heal-over-Time spell. | — |
| Rejuvenation *(rank 2)* | Bloom | Heal-over-Time | 16 | instant | — | Heals 64 over 8s. | 4.0 |
| Renew | Bloom | Heal-over-Time | 12 | instant | — | Heals 40 over 8s. | 3.3 |
| Ripening | Bloom | — | passive | passive | — | Your Delayed heals on a fighter below 50% health heal 50% more. Offered once you own a Delayed spell. | — |
| Tranquility | Bloom | Heal-over-Time, Multi-target | 30 | 2s | — | Every fighter heals 12 over 6s. | 0.4 per fighter (2.4 with 6) |
| Aegis of Light | Ward | Shield, Multi-target | 35 | 1.5s | — | Every fighter gets a 12 Shield for 6s. | 0.3 per fighter (2.1 with 6) |
| Bulwark | Ward | — | passive | passive | — | Cancels Diminishing shields: your Shield effects stack at full strength and absorb 15% more. Offered once you own a Shield spell. | — |
| Divine Protection | Ward | Mitigation | 20 | instant | 12s | The fighter takes 50% less damage for 5s. | — |
| Guardian Ward | Ward | Shield | 18 | instant | — | Absorbs the next 25 damage for 6s, then heals 20 when it ends. | 2.5 |
| Sanctuary | Ward | — | passive | passive | — | When you cast a Mitigation spell, that fighter gains a Shield of 15 for 6s. Offered once you own a Mitigation spell. | — |
| Shield | Ward | Shield | 14 | instant | — | Absorbs the next 30 damage for 8s. | 2.1 |
| Shield II *(rank 2)* | Ward | Shield | 17 | instant | — | Absorbs the next 45 damage for 8s. | 2.6 |
| Spirit Surge | Ward | Direct | 10 | instant | 4s | Consumes the Shield effects on this fighter and heals for 150% of what they had left. Offered once you own a Shield spell. | — |
| Time Stop | Ward | Mitigation | 25 | instant | 20s | The fighter takes no damage for 2.5s. | — |
| Vital Bond | Ward | — | passive | passive | — | When one of your Shield effects breaks, the fighters on each side gain a Shield of 10 for 5s. Offered once you own a Shield spell. | — |
| Watchful Eye | Ward | — | passive | passive | — | When you cast a Mitigation spell on a fighter below 40% health, that fighter is healed for 25. Offered once you own a Mitigation spell. | — |
| Double Down | Mending | — | passive | passive | — | When one of your Direct heals lands, that fighter is healed for 100% of it (every 4th time). Offered once you own a Direct spell. | — |
| Wildgrowth | Bloom | — | passive | passive | — | When you cast a Heal-over-Time spell, the Heal-over-Time effects on every fighter last 2s longer. Offered once you own a Heal-over-Time spell. | — |
| Harvest | Bloom | — | passive | passive | — | When one of your Delayed heals lands, your most injured fighter is healed for 50% of it. Offered once you own a Delayed spell. | — |
| Shatterpoint | Ward | — | passive | passive | — | When one of your Shield effects breaks, every fighter is healed for 40% of what it could absorb (up to 12). Offered once you own a Shield spell. | — |
| Bastion | Ward | — | passive | passive | — | When you cast a Mitigation spell, every fighter gains a Shield of 8 for 5s. Offered once you own a Mitigation spell. | — |
| Chain Reaction | Any school | — | passive | passive | — | When you cast a Multi-target spell, your most injured fighter is healed for 15. Offered once you own a Multi-target spell. | — |
| Chain Heal | Any school | Direct, Multi-target | 26 | 2s | — | Heals 30, and the fighters on each side for 15. | 2.3 |
| Divine Channel | Any school | — | 0 | 3s | 30s | Restores 50 of your mana. | — |
| Lingering Light | Any school | — | passive | passive | — | When you cast a Multi-target spell, that fighter gains a Heal-over-Time of 3 each second for 4s. Offered once you own a Multi-target spell. | — |
| Mana Conduit | Any school | — | passive | passive | — | Overhealing isn't wasted: you get 20% of it back as mana. | — |
| Mend Wounds | Any school | Direct, Heal-over-Time | 16 | 1s | — | Heals 20, then heals 15 over 5s. | 2.2 |
| Second Wind | Any school | — | passive | passive | — | Cancels Exhaustion: running your mana dry restores 30 mana instead (once every 20s). | — |

New in Phase E (2026-10-25): passives now come only from beating the Baron, and six
"Baron-worthy" passives joined (Double Down, Wildgrowth, Harvest, Shatterpoint, Bastion,
Chain Reaction), all data on the generic tag trigger. 43 entries: 21 spells you cast (with
ranks), 18 passives. The original list's "keystone spells" below became passives.

New in Phase D (#70): Promise of Light, Hasten, Tranquility, Aegis of Light, Ripening,
Lingering Light, Rising Tide, Sanctuary, Watchful Eye; Divine Protection, Time Stop and Guardian
Angel gained the **Mitigation** tag (named Protection until 2026-10-24). Every passive is now data on the generic tag trigger (#65).
Party-wide spells (Tranquility, Aegis of Light) are cheap per fighter and get better the bigger
the party: big and efficient at scale, but slow.

### Not in the game yet
Cleanse (Phase F) · Harmonize, Decoy,
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

