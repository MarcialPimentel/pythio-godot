# Any-school passive: wasted healing comes back as mana.
class_name ManaConduitRule
extends PassiveRule

@export_range(0.0, 1.0) var refund: float = 0.2

func on_healed(_target: Node, _amount: float, overheal: float, _tags: Array, _opts: Dictionary) -> void:
	if overheal > 0.0:
		EffectSystem.gain_mana(overheal * refund)
		EffectSystem.passive_fired(self)

func describe() -> String:
	return "Overhealing isn't wasted: you get %d%% of it back as mana." % roundi(refund * 100.0)
