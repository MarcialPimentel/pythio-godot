# Absorbs damage until used up or until it fades. Can heal when it ends.
class_name ShieldStatus
extends Status

var remaining: float = 0.0
var heal_on_end: float = 0.0

func _init(p_amount: float = 30.0, p_duration: float = 8.0, p_heal_on_end: float = 0.0) -> void:
	kind = "SHIELD"
	remaining = p_amount
	duration = p_duration
	time_left = p_duration
	heal_on_end = p_heal_on_end

func on_end(hc: HealthComponent, expired: bool) -> void:
	EffectSystem.shield_ended(target, self, not expired, maxf(0.0, remaining))
	if heal_on_end > 0.0 and not hc.is_dead:
		EffectSystem.heal(target, heal_on_end, spell, [])
