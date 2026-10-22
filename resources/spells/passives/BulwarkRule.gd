# Ward passive, mirror of Diminishing shields: shields stack fully and absorb a bit more.
class_name BulwarkRule
extends PassiveRule

@export var bonus: float = 0.15

func modify_shield(amount: float, _target: Node, _spell: SpellData) -> float:
	EffectSystem.passive_fired(self)
	return amount * (1.0 + bonus)

func describe() -> String:
	return "Cancels Diminishing shields: your {SHIELD} effects stack at full strength and absorb %d%% more." % roundi(bonus * 100.0)
