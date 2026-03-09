@tool

extends Node

@export var total_rounds: int = 5

@export_group("Round Scaling")
@export var round_time_base: float = .5
@export var round_time_growth: float = .5  # per round

@export_group("Mana")
@export var max_mana_base: float = 100.0
@export var max_mana_growth: float = 8.0
@export var regen_rate_base: float = 4.0

@export_group("Damage & Burst")
@export var base_dps: float = 3.0
@export var dps_growth: float = 0.7
@export var burst_interval: float = 5.0
@export var burst_telegraph_time: float = 1.2

@export var armor_dps_multipliers: Dictionary = {"LIGHT": 1.6, "MEDIUM": 1.2, "HEAVY": 0.8}

func get_round_time(round: int) -> float:
	return round_time_base + (round - 1) * round_time_growth

func get_max_mana(round: int) -> float:
	return max_mana_base + (round - 1) * max_mana_growth

func get_base_dps(round: int) -> float:
	return base_dps + (round - 1) * dps_growth
