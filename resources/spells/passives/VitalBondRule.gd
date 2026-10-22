# Ward passive: a shield that breaks passes a small shield to the fighters next door.
class_name VitalBondRule
extends PassiveRule

@export var shield_amount: float = 10.0
@export var duration: float = 5.0

func on_shield_ended(target: Node, status, broken: bool, _remaining: float) -> void:
	if not broken or status.has_meta("bond"):
		return   # only real breaks, and bond shields don't chain
	var gave := false
	for other in TargetSystem.neighbors_of(target):
		var s := ShieldStatus.new(shield_amount, duration)
		s.label = "Vital Bond"
		s.set_meta("bond", true)
		EffectSystem.add_status(other, s, null)
		EffectSystem.effect_applied.emit("shield", other, shield_amount, "")
		gave = true
	if gave:
		EffectSystem.combo(target, "Vital Bond")
		EffectSystem.passive_fired(self)

func describe() -> String:
	return "When one of your {SHIELD} effects breaks, the fighters on each side gain a %d {SHIELD} for %ds." % [roundi(shield_amount), roundi(duration)]
