# Any-school passive, mirror of Exhaustion: running dry gives you a burst of mana instead.
class_name SecondWindRule
extends PassiveRule

@export var mana: float = 30.0
@export var cooldown: float = 20.0
var _ready_at := 0.0

func on_mana_empty() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _ready_at:
		return
	_ready_at = now + cooldown
	EffectSystem.gain_mana(mana)
	EffectSystem.passive_fired(self)

func describe() -> String:
	return "Cancels Exhaustion: running your mana dry restores %d mana instead (once every %ds)." % [roundi(mana), roundi(cooldown)]
