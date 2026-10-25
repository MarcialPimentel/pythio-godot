# Removes debuffs that can be cleansed (Phase F): Poison, Hex and Dread. Bleed can't be
# cleansed. `only` limits it to some kinds (Mend Wounds: Poison). `immunity` keeps new
# debuffs off for a few seconds (Purify).
class_name CleanseEffect
extends SpellEffect

## Only these debuffs (empty = every debuff that can be cleansed).
@export var only: Array[String] = []
## Seconds the fighter can't get a new debuff afterwards (0 = none).
@export var immunity: float = 0.0

func apply(spell: SpellData, target: Node) -> void:
	EffectSystem.cleanse(target, spell, only)
	if immunity > 0.0:
		var s := Status.new()
		s.kind = "IMMUNE"
		s.label = "Purified"
		s.duration = immunity
		s.time_left = immunity
		EffectSystem.add_status(target, s, spell)

func describe() -> String:
	var what := "Removes Poison, Hex and Dread" if only.is_empty() else "Removes " + " and ".join(only.map(func(x): return x.capitalize()))
	if immunity > 0.0:
		return "%s from the fighter; no new debuffs for %ss." % [what, n(immunity)]
	return "%s from the fighter." % what
