# Reduces the damage a fighter takes for a while (1.0 = no damage at all).
class_name ProtectEffect
extends SpellEffect

@export_range(0.0, 1.0) var reduction: float = 0.5
@export var duration: float = 5.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.add_status(target, ProtectStatus.new(reduction, duration), spell)
	EffectSystem.effect_applied.emit("protect", target, reduction, "")

func describe() -> String:
	if reduction >= 1.0:
		return "The fighter takes no damage for %ss." % n(duration)
	return "The fighter takes %d%% less damage for %ss." % [roundi(reduction * 100.0), n(duration)]
