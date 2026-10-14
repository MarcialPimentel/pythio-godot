@tool

extends Node

@export var total_rounds: int = 5

@export_group("Round Scaling")
# From the original design: round 1 is short, later rounds 20s growing to a 30s cap.
@export var first_round_time: float = 10.0
@export var round_time_base: float = 20.0       # rounds 2+
@export var round_time_growth: float = 1.0      # added every `round_time_growth_every` rounds
@export var round_time_growth_every: int = 3
@export var round_time_max: float = 30.0

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
	if round <= 1:
		return first_round_time
	var growth := floorf(float(round - 1) / maxi(1, round_time_growth_every)) * round_time_growth
	return minf(round_time_max, round_time_base + growth)

func get_max_mana(round: int) -> float:
	return max_mana_base + (round - 1) * max_mana_growth

func get_base_dps(round: int) -> float:
	return base_dps + (round - 1) * dps_growth
