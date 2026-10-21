# Heals once when its timer runs out (Lifebloom, echoes).
class_name DelayedHealStatus
extends Status

var amount: float = 0.0
var is_echo: bool = false

func _init(p_amount: float = 40.0, p_delay: float = 6.0, p_is_echo: bool = false) -> void:
	kind = "DELAYED"
	amount = p_amount
	duration = p_delay
	time_left = p_delay
	is_echo = p_is_echo

## Echoes stack (each heal makes its own); a recast Lifebloom refreshes.
func key() -> String:
	return super.key() + (":%d" % get_instance_id() if is_echo else "")

func on_end(hc: HealthComponent, expired: bool) -> void:
	if expired and not hc.is_dead:
		EffectSystem.heal(target, amount, spell, tags, {"echo": is_echo})
