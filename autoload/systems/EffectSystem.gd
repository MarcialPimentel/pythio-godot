# autoload/systems/EffectSystem.gd
extends Node

signal effect_applied(effect_type: String, target, value: float, vfx_color: String)

# Apply effects to targets
func apply_effect(target, spell: SpellData):
	if not target or not spell:
		return
	
	match spell.effect_type:
		"instant_heal":
			target.heal(spell.effect_value)
			effect_applied.emit("heal", target, spell.effect_value, spell.vfx_color)
		"shield":
			target.add_shield(spell.effect_value, spell.effect_duration)
			effect_applied.emit("shield", target, spell.effect_value, spell.vfx_color)
		"hot":
			target.apply_hot(spell.effect_value, spell.effect_duration)
			effect_applied.emit("hot", target, spell.effect_value, spell.vfx_color)
		_:
			print("Unknown effect type: ", spell.effect_type)