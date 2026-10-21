# Restores the healer's mana.
class_name ManaEffect
extends SpellEffect

@export var amount: float = 50.0

func apply(_spell: SpellData, _target: Node) -> void:
	EffectSystem.gain_mana(amount)

func describe() -> String:
	return "Restores %s of your mana." % n(amount)
