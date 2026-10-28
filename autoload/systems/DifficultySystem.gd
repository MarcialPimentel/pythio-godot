@tool

extends Node

## The Crimson Baron shows up on every Nth round (5 → rounds 5, 10, 15 …).
@export var boss_every: int = 5

@export_group("Between rounds")
## "Job finished" screen after a cleared round: how long it holds (owner, 2026-10-24).
@export var job_finished_time: float = 1.6
## After a pick or Next party screen appears, clicks and keys are ignored this long, so
## a click from the round can't pick a card or start the next round by accident.
@export var screen_input_guard: float = 0.5

## The last N seconds of a round: the timer flashes and pops each second (owner, 2026-10-24).
@export var final_countdown_time: float = 5.0

@export_group("Debuffs (Phase F)")
## Debuffs start on this round (owner, 2026-10-25: round 6, all four kinds).
@export var debuff_start_round: int = 6
## Seconds between debuffs in the first debuff round, minus this per later round, never
## below the minimum. The first one comes after half an interval.
@export var debuff_interval_first: float = 9.0
@export var debuff_interval_step: float = 0.5
@export var debuff_interval_min: float = 4.0
## Debuff damage grows this much per round after the first debuff round (0.08 = +8%).
@export var debuff_growth: float = 0.08
## How often each kind is picked (relative).
@export var debuff_weights: Dictionary = {"POISON": 1.0, "BLEED": 1.0, "HEX": 1.0, "DREAD": 1.0}
## Poison: damage per second per stack, stacks, seconds.
@export var poison_dps: float = 1.2
@export var poison_max_stacks: int = 3
@export var poison_time: float = 15.0
## Bleed: damage per second until healed above this share of max health (or bandaged).
@export var bleed_dps: float = 2.0
@export var bleed_end_above: float = 0.8
@export var bleed_time: float = 30.0
## Bleed opens a wound: a fighter above this share of max health is hit down to it first
## (a shield can absorb the wound, and then the bleed stops at once).
@export var bleed_wound_to: float = 0.7
## Hex: heals on the fighter are multiplied by this, for this long.
@export var hex_heal_taken: float = 0.5
@export var hex_time: float = 8.0
## Dread: falling to this share of max health kills; lasts this long.
@export var dread_threshold: float = 0.3
@export var dread_time: float = 15.0

@export_group("Round Scaling")
# Endless pacing (owner, 2026-10-21): rounds stay short and frantic, under 30s.
@export var first_round_time: float = 15.0
@export var round_time_growth: float = 1.0      # seconds added each round
@export var round_time_max: float = 25.0

@export_group("Mana")
@export var max_mana_base: float = 100.0
@export var max_mana_growth: float = 8.0
@export var regen_rate_base: float = 4.0
## Mana regen grows a little each round so long runs aren't starved (per round after the 1st).
@export var regen_growth: float = 0.25
## Share of max mana restored at the start of each new round (original design: half).
@export_range(0.0, 1.0) var round_start_mana_refill: float = 0.5

@export_group("Damage & Burst")
## Steady damage per fighter (before armor): base + growth per round. Softened 2026-10-21
## (was 3.0 + 0.7/round) so a new player's first deaths land around rounds 6–8.
@export var base_dps: float = 2.6
@export var dps_growth: float = 0.35
@export var burst_interval: float = 5.0
## Seconds of red warning before a burst lands (time to react with a shield or heal).
@export var burst_telegraph_time: float = 1.5
## Burst hit size: base + growth per round, then × the fighter's armor multiplier.
@export var burst_damage_base: float = 18.0
@export var burst_damage_growth: float = 1.5
## The Crimson Baron's bursts hit this many times harder.
@export var boss_burst_multiplier: float = 4.0

## Gentler opening while you only have one or two spells: damage multiplier for rounds
## 1, 2, 3 … (rounds past the list take full damage). Applies to steady damage and bursts.
@export var early_damage_scale: PackedFloat32Array = [0.6, 0.75, 0.9]

## Damage taken by armor type. Light was 1.6 / medium 1.2 until 2026-10-21: half of all
## fighters are light, so that made rounds 3–4 a wall.
@export var armor_dps_multipliers: Dictionary = {"LIGHT": 1.35, "MEDIUM": 1.1, "HEAVY": 0.8}

func get_round_time(round: int) -> float:
	return minf(round_time_max, first_round_time + round_time_growth * maxi(0, round - 1))

func is_boss_round(round: int) -> bool:
	return boss_every > 0 and round % boss_every == 0

## 1 for the Baron's first appearance, 2 for his second, …
func boss_appearance(round: int) -> int:
	return maxi(1, round / maxi(1, boss_every))

func get_regen_rate(round: int) -> float:
	return regen_rate_base + regen_growth * maxi(0, round - 1)

func get_max_mana(round: int) -> float:
	return max_mana_base + (round - 1) * max_mana_growth

func get_burst_damage(round: int, armor_type: String, is_boss: bool) -> float:
	var armor_mult: float = armor_dps_multipliers.get(armor_type, 1.0)
	var dmg: float = (burst_damage_base + burst_damage_growth * maxi(0, round - 1)) * armor_mult
	return dmg * (boss_burst_multiplier if is_boss else 1.0) * damage_scale(round)

func get_base_dps(round: int) -> float:
	return (base_dps + (round - 1) * dps_growth) * damage_scale(round)


## Seconds between debuffs in `round` (0 = no debuffs yet).
func get_debuff_interval(round: int) -> float:
	if debuff_start_round <= 0 or round < debuff_start_round:
		return 0.0
	return maxf(debuff_interval_min, debuff_interval_first - debuff_interval_step * (round - debuff_start_round))


## Debuff damage multiplier for `round`.
func get_debuff_scale(round: int) -> float:
	return 1.0 + debuff_growth * maxi(0, round - debuff_start_round)


func damage_scale(round: int) -> float:
	var i := round - 1
	return early_damage_scale[i] if i >= 0 and i < early_damage_scale.size() else 1.0
