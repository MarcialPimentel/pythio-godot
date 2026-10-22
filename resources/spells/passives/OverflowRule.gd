# Mending passive, mirror of Saturation: overheal becomes a small shield.
class_name OverflowRule
extends PassiveRule

@export_range(0.0, 1.0) var share: float = 0.5
@export var max_shield: float = 20.0
@export var seconds: float = 5.0

func on_healed(target: Node, _amount: float, overheal: float, _tags: Array, opts: Dictionary) -> void:
	if overheal < 5.0 or opts.get("quiet", false):
		return
	var s := ShieldStatus.new(minf(overheal * share, max_shield), seconds)
	s.label = "Overflow"
	EffectSystem.add_status(target, s, null)
	EffectSystem.effect_applied.emit("shield", target, s.remaining, "")
	EffectSystem.passive_fired(self)

func describe() -> String:
	return "Cancels Saturation: overhealing turns %d%% of the overheal into a {SHIELD} (up to %d, %ss)." % [roundi(share * 100.0), roundi(max_shield), SpellEffect.n(seconds)]
