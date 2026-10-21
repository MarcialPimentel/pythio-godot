# Combo payoff: turns the shields on the fighter into healing.
class_name ConsumeShieldsEffect
extends SpellEffect

@export var ratio: float = 1.5

func apply(spell: SpellData, target: Node) -> void:
	var hc: HealthComponent = target.health_comp
	var total := 0.0
	for s in hc.get_statuses("SHIELD"):
		total += (s as ShieldStatus).remaining
		hc.statuses.erase(s)   # consumed, not broken: no end effects
	if total <= 0.0:
		return
	hc.shield_changed.emit(hc.shield_amount)
	hc.statuses_changed.emit()
	EffectSystem.combo(target, "Surge")
	EffectSystem.heal(target, total * ratio, spell, spell.tags)

func describe() -> String:
	return "Consumes the {SHIELD} effects on this fighter and heals for %d%% of what they had left." % roundi(ratio * 100.0)
