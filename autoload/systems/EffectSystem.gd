# autoload/systems/EffectSystem.gd
# Applies a spell's effect to a fighter's HealthComponent and announces it
# (effect_applied is the hook for VFX, floating numbers and combos later).
extends Node

signal effect_applied(effect_type: String, target, value: float, vfx_color: String)

func apply_effect(target, spell: SpellData) -> void:
	if not is_instance_valid(target) or not spell:
		return
	var hc: HealthComponent = target.health_comp if "health_comp" in target else null
	if not hc:
		push_warning("EffectSystem: target has no HealthComponent")
		return

	match spell.effect_type:
		"instant_heal":
			hc.heal(spell.effect_value)
			effect_applied.emit("heal", target, spell.effect_value, spell.vfx_color)
		"shield":
			hc.apply_shield(spell.effect_value, spell.effect_duration)
			effect_applied.emit("shield", target, spell.effect_value, spell.vfx_color)
		"hot":
			hc.apply_hot(spell.effect_value, spell.effect_duration)
			effect_applied.emit("hot", target, spell.effect_value, spell.vfx_color)
		_:
			push_warning("Unknown effect type: %s" % spell.effect_type)
