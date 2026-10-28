# Combo payoff: turns the shields on the fighter into healing.
class_name ConsumeShieldsEffect
extends SpellEffect

@export var ratio: float = 1.5

func apply(spell: SpellData, target: Node) -> void:
	var hc: HealthComponent = target.health_comp
	var total := 0.0
	for s in hc.get_statuses("SHIELD"):
		total += (s as ShieldStatus).remaining
		hc.drop_status(s)   # consumed, not broken: no end effects
	if total <= 0.0:
		return
	EffectSystem.combo(target, spell.display_name if spell else "Surge")
	EffectSystem.heal(target, total * ratio, spell, spell.tags)

func would_combo(_spell: SpellData, target: Node) -> bool:
	return target.health_comp.shield_amount > 0.0

func would_heal(spell: SpellData, target: Node) -> bool:
	return would_combo(spell, target)

func describe() -> String:
	return "Consumes the {SHIELD} effects on this fighter and heals for %d%% of what they had left." % roundi(ratio * 100.0)
