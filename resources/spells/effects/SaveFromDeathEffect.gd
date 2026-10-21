# For a while, a killing blow leaves the fighter at 1 health and heals them instead.
class_name SaveFromDeathEffect
extends SpellEffect

@export var duration: float = 6.0
@export var heal_amount: float = 30.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.add_status(target, SaveStatus.new(heal_amount, duration), spell)
	EffectSystem.effect_applied.emit("protect", target, 0.0, "")

func describe() -> String:
	return "For %ss, a killing blow leaves the fighter at 1 health instead, then heals them for %s." % [n(duration), n(heal_amount)]
