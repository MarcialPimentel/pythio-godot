@tool

extends Node

## Rounds in a run. 0 = endless (keep going until a fighter dies).
@export var total_rounds: int = 0
## The Crimson Baron shows up on every Nth round (5 → rounds 5, 10, 15 …).
@export var boss_every: int = 5

@export_group("Round Scaling")
# Endless pacing (owner, 2026-10-21): rounds stay short and frantic, under 30s.
@export var first_round_time: float = 15.0
@export var round_time_growth: float = 1.0      # seconds added each round
@export var round_time_max: float = 25.0

@export_group("Mana")
@export var max_mana_base: float = 100.0
@export var max_mana_growth: float = 8.0
@export var regen_rate_base: float = 4.0
## Share of max mana restored at the start of each new round (original design: half).
@export_range(0.0, 1.0) var round_start_mana_refill: float = 0.5

@export_group("Damage & Burst")
@export var base_dps: float = 3.0
@export var dps_growth: float = 0.7
@export var burst_interval: float = 5.0
@export var burst_telegraph_time: float = 1.2

@export var armor_dps_multipliers: Dictionary = {"LIGHT": 1.6, "MEDIUM": 1.2, "HEAVY": 0.8}

func get_round_time(round: int) -> float:
	return minf(round_time_max, first_round_time + round_time_growth * maxi(0, round - 1))

func is_endless() -> bool:
	return total_rounds <= 0

func is_boss_round(round: int) -> bool:
	return boss_every > 0 and round % boss_every == 0

## 1 for the Baron's first appearance, 2 for his second, …
func boss_appearance(round: int) -> int:
	return maxi(1, round / maxi(1, boss_every))

func get_max_mana(round: int) -> float:
	return max_mana_base + (round - 1) * max_mana_growth

func get_base_dps(round: int) -> float:
	return base_dps + (round - 1) * dps_growth
