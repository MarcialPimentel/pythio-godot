# A shield that absorbs damage; can heal when it breaks or fades. Recasting refreshes it.
class_name ShieldEffect
extends SpellEffect

@export var amount: float = 30.0
@export var duration: float = 8.0
## Heals this much when the shield breaks or fades.
@export var heal_on_end: float = 0.0
## Shields every living fighter instead (Aegis of Light).
@export var whole_party: bool = false

func apply(spell: SpellData, target: Node) -> void:
	var who: Array = [target]
	if whole_party:
		who = TargetSystem.targets.filter(func(t): return is_instance_valid(t) and not t.health_comp.is_dead)
	for t in who:
		var final := EffectSystem.shield_amount(t, amount, spell)
		EffectSystem.add_status(t, ShieldStatus.new(final, duration, heal_on_end), spell)
		EffectSystem.effect_applied.emit("shield", t, final, "")

func describe() -> String:
	var s := ("Every fighter gets a %s {SHIELD} for %ss." % [n(amount), n(duration)]) if whole_party \
		else "Absorbs the next %s damage for %ss." % [n(amount), n(duration)]
	if heal_on_end > 0.0:
		s += " When it breaks or fades, heals %s." % n(heal_on_end)
	return s
