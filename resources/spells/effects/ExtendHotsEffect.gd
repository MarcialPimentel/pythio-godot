# Combo: lengthens every heal-over-time already on the fighter.
class_name ExtendHotsEffect
extends SpellEffect

@export var seconds: float = 5.0

func apply(spell: SpellData, target: Node) -> void:
	var hots: Array = target.health_comp.get_statuses("HOT")
	for s in hots:
		s.time_left += seconds
	if not hots.is_empty():
		EffectSystem.combo(target, "%s +%ss" % [spell.display_name if spell else "Heal-over-Time", n(seconds)])

func describe() -> String:
	return "Extends every {HOT} effect on the fighter by %ss." % n(seconds)
