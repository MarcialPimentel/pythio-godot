# Battlefield rule (soft): a big overheal makes the next heal on that fighter weaker.
# Heal-over-time ticks and bandages never cause or suffer it.
class_name SaturationRule
extends PassiveRule

@export var overheal_threshold: float = 8.0
@export_range(0.0, 1.0) var weaker_by: float = 0.3
@export var seconds: float = 3.0

func on_healed(target: Node, _amount: float, overheal: float, _tags: Array, opts: Dictionary) -> void:
	if overheal < overheal_threshold or opts.get("quiet", false) or opts.get("echo", false):
		return
	var s := Status.new()
	s.kind = "SATURATED"
	s.label = "Saturated"
	s.duration = seconds
	s.time_left = seconds
	target.health_comp.add_status(s)
	EventBus.rule_triggered.emit("saturated", target)

func modify_heal(amount: float, target: Node, _tags: Array, opts: Dictionary) -> float:
	if opts.get("quiet", false):
		return amount
	var hc: HealthComponent = target.health_comp
	var sat := hc.get_statuses("SATURATED")
	if sat.is_empty():
		return amount
	hc.statuses.erase(sat[0])
	hc.statuses_changed.emit()
	return amount * (1.0 - weaker_by)

func describe() -> String:
	return "Overhealing a fighter by %d or more makes the next heal on them %d%% weaker (for %ss)." % [roundi(overheal_threshold), roundi(weaker_by * 100.0), SpellEffect.n(seconds)]
