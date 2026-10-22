# Battlefield rule: stacking shields on one fighter is wasteful.
class_name DiminishingShieldsRule
extends PassiveRule

@export_range(0.0, 1.0) var factor: float = 0.5

func modify_shield(amount: float, target: Node, _spell: SpellData) -> float:
	return amount * factor if target.health_comp.shield_amount > 0.0 else amount

func describe() -> String:
	return "A second {SHIELD} on a fighter who already has one absorbs %d%% less." % roundi((1.0 - factor) * 100.0)
