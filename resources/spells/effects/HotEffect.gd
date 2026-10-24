# A heal-over-time: heals a fixed amount every second. Recasting refreshes it.
class_name HotEffect
extends SpellEffect

@export var per_second: float = 5.0
@export var duration: float = 8.0
## Also puts the same heal-over-time on the fighters on each side.
@export var include_neighbors: bool = false
## Puts it on every living fighter instead (Tranquility).
@export var whole_party: bool = false

func apply(spell: SpellData, target: Node) -> void:
	var who: Array = [target]
	if whole_party:
		who = TargetSystem.targets.filter(func(t): return is_instance_valid(t) and not t.health_comp.is_dead)
	elif include_neighbors:
		who.append_array(TargetSystem.neighbors_of(target))
	for t in who:
		EffectSystem.add_status(t, HotStatus.new(per_second, duration), spell)
		EffectSystem.effect_applied.emit("hot", t, per_second * duration, "")

func would_heal(_spell: SpellData, _target: Node) -> bool:
	return true

func describe() -> String:
	if whole_party:
		return "Every fighter heals %s over %ss." % [n(per_second * duration), n(duration)]
	if include_neighbors:
		return "Heals this fighter and the ones on each side for %s over %ss." % [n(per_second * duration), n(duration)]
	return "Heals %s over %ss." % [n(per_second * duration), n(duration)]
