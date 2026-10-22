# Mending passive: Direct heals hit harder on fighters who are close to falling.
class_name SeraphicBlessingRule
extends PassiveRule

@export_range(0.0, 1.0) var below_health: float = 0.4
@export var bonus: float = 0.3

func modify_heal(amount: float, target: Node, tags: Array, opts: Dictionary) -> float:
	if not tags.has(SpellTags.DIRECT) or opts.get("echo", false):
		return amount
	var hc: HealthComponent = target.health_comp
	if hc.current_health / maxf(1.0, hc.max_health) >= below_health:
		return amount
	EffectSystem.combo(target, "Blessed")
	EffectSystem.passive_fired(self)
	return amount * (1.0 + bonus)

func would_combo(spell: SpellData, target: Node) -> bool:
	var hc: HealthComponent = target.health_comp
	return spell.tags.has(SpellTags.DIRECT) and hc.current_health / maxf(1.0, hc.max_health) < below_health

func describe() -> String:
	return "Your {DIRECT} heals on a fighter below %d%% health heal %d%% more." % [roundi(below_health * 100.0), roundi(bonus * 100.0)]
