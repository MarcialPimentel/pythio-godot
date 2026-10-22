# Combo: your Delayed heals already on the fighter land right now, and bigger (Hasten).
class_name HastenDelayedEffect
extends SpellEffect

## 0.25 = they land 25% bigger.
@export var bonus: float = 0.25

func apply(spell: SpellData, target: Node) -> void:
	var hc: HealthComponent = target.health_comp
	var landed := false
	for s in _delayed(hc):
		hc.statuses.erase(s)   # it lands now instead of later (no end-of-timer heal)
		EffectSystem.heal(target, s.amount * (1.0 + bonus), s.spell, s.tags)
		landed = true
	if landed:
		hc.statuses_changed.emit()
		EffectSystem.combo(target, "%s!" % (spell.display_name if spell else "Hasten"))

func would_combo(_spell: SpellData, target: Node) -> bool:
	return not _delayed(target.health_comp).is_empty()

## Delayed heals you cast (echoes don't count: they're repeats of Direct heals).
func _delayed(hc: HealthComponent) -> Array:
	return hc.get_statuses("DELAYED").filter(func(s): return not s.is_echo)

func describe() -> String:
	return "Your {DELAYED} heals on the fighter land now, %d%% bigger." % roundi(bonus * 100.0)
