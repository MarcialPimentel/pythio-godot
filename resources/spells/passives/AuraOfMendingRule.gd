# Bloom passive: heal-over-time ticks splash onto the fighters next door.
class_name AuraOfMendingRule
extends PassiveRule

@export_range(0.0, 1.0) var share: float = 0.3

func on_hot_tick(target: Node, amount: float, _status) -> void:
	for other in TargetSystem.neighbors_of(target):
		var healed := EffectSystem.heal(other, amount * share, null, [], {"quiet": true, "no_echo": true})
		if healed > 0.0:
			EffectSystem.effect_applied.emit("hot_tick", other, amount * share, "")
			EffectSystem.passive_fired(self)

func describe() -> String:
	return "Each time one of your {HOT} effects heals, the fighters on each side are healed for %d%% of it." % roundi(share * 100.0)
