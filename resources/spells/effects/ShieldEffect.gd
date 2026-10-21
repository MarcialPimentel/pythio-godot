# A shield that absorbs damage; can heal when it breaks or fades. Recasting refreshes it.
class_name ShieldEffect
extends SpellEffect

@export var amount: float = 30.0
@export var duration: float = 8.0
## Heals this much when the shield breaks or fades.
@export var heal_on_end: float = 0.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.add_status(target, ShieldStatus.new(amount, duration, heal_on_end), spell)
	EffectSystem.effect_applied.emit("shield", target, amount, "")

func describe() -> String:
	var s := "Absorbs the next %s damage for %ss." % [n(amount), n(duration)]
	if heal_on_end > 0.0:
		s += " When it breaks or fades, heals %s." % n(heal_on_end)
	return s
