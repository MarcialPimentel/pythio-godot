# Heals the target now; can also heal the fighters on each side, or the most injured other fighter.
class_name HealEffect
extends SpellEffect

@export var amount: float = 30.0
## Also heals each fighter next to the target by this much.
@export var neighbor_amount: float = 0.0
## Also heals the most injured other fighter by this much.
@export var lowest_other_amount: float = 0.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.heal(target, amount, spell, spell.tags)
	if neighbor_amount > 0.0:
		for other in TargetSystem.neighbors_of(target):
			EffectSystem.heal(other, neighbor_amount, spell, spell.tags)
	if lowest_other_amount > 0.0:
		var other = TargetSystem.most_injured(target)
		if other:
			EffectSystem.heal(other, lowest_other_amount, spell, spell.tags)

func describe() -> String:
	var s := "Heals %s." % n(amount)
	if neighbor_amount > 0.0:
		s += " Also heals the fighters on each side for %s." % n(neighbor_amount)
	if lowest_other_amount > 0.0:
		s += " Also heals your most injured other fighter for %s." % n(lowest_other_amount)
	return s
