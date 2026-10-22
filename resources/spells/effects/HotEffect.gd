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
		return "Every fighter heals %s each second for %ss (%s each)." % [n(per_second), n(duration), n(per_second * duration)]
	var s := "Heals %s over %ss (%s each second)." % [n(per_second * duration), n(duration), n(per_second)]
	if include_neighbors:
		s += " Also on the fighters on each side."
	return s
