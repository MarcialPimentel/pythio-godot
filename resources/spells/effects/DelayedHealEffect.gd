# Heals once after a delay. Recasting restarts the timer.
class_name DelayedHealEffect
extends SpellEffect

@export var amount: float = 45.0
@export var delay: float = 6.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.add_status(target, DelayedHealStatus.new(amount, delay), spell)
	EffectSystem.effect_applied.emit("delayed", target, amount, "")

func describe() -> String:
	return "After %ss, heals %s." % [n(delay), n(amount)]
