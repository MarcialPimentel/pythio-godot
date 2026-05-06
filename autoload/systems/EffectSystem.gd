# autoload/systems/EffectSystem.gd
extends Node

signal effect_applied(effect_type: String, target, value: float, color: String)

func apply_effect(spell: SpellData, target, caster = null):
	if not target or not target.has_method("receive_effect"):
		return
	
	match spell.effect_type:
		"instant_heal":
			target.receive_effect("heal", spell.effect_value)
			emit_signal("effect_applied", "heal", target, spell.effect_value, spell.vfx_color)
		"shield":
			target.receive_effect("shield", spell.effect_value, spell.effect_duration)
			emit_signal("effect_applied", "shield", target, spell.effect_value, spell.vfx_color)
		_:
			print("Unknown effect type: ", spell.effect_type)
	
	# Optional: Pythio flavor quip
	if spell.flavor_quip:
		EventBus.emit_signal("quip_triggered", spell.flavor_quip)
