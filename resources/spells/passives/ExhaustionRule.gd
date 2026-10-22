# Battlefield rule: running your mana dry slows its refill for a while.
class_name ExhaustionRule
extends PassiveRule

@export var seconds: float = 4.0
@export_range(0.0, 1.0) var regen_factor: float = 0.5

func on_mana_empty() -> void:
	GameManager.exhaust(seconds, regen_factor)

func describe() -> String:
	return "Run your mana dry (too little left for any spell) and it refills at %d%% speed for %ss." % [roundi(regen_factor * 100.0), SpellEffect.n(seconds)]
