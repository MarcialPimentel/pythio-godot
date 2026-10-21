# Combo setup: for a while, Direct heals on the fighter repeat part of themselves later.
class_name EchoMarkEffect
extends SpellEffect

@export var duration: float = 8.0
@export_range(0.0, 1.0) var fraction: float = 0.5
@export var delay: float = 2.0

func apply(spell: SpellData, target: Node) -> void:
	var mark := EchoStatus.new(fraction, delay, duration)
	mark.label = "Echo"
	EffectSystem.add_status(target, mark, spell)
	EffectSystem.effect_applied.emit("delayed", target, 0.0, "")

func describe() -> String:
	return "For %ss, {DIRECT} heals on this fighter echo: %d%% of each heal repeats %ss later." % [n(duration), roundi(fraction * 100.0), n(delay)]
