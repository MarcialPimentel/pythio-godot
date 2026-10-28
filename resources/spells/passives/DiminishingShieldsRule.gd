# Battlefield rule: stacking shields on one fighter is wasteful.
class_name DiminishingShieldsRule
extends PassiveRule

@export_range(0.0, 1.0) var factor: float = 0.5

func modify_shield(amount: float, target: Node, spell: SpellData) -> float:
	# Owner, 2026-10-28: recasting the same shield refreshes it at full strength; only a
	# different shield on top counts as "a second shield".
	for s in target.health_comp.statuses:
		if s is ShieldStatus and s.remaining > 0.0 and not (spell and s.spell == spell):
			return amount * factor
	return amount

func describe() -> String:
	return "A different {SHIELD} on a fighter who already has one absorbs %d%% less (recasting the same one refreshes it)." % roundi((1.0 - factor) * 100.0)
