# resources/spells/passives/PassiveRule.gd
# What a passive spell does. The effect system calls these hooks on every passive in the
# spellbook; a passive overrides only the ones it cares about.
class_name PassiveRule
extends Resource

## Change the size of a heal before it lands. `opts` carries flags such as "echo".
func modify_heal(amount: float, _target: Node, _tags: Array, _opts: Dictionary) -> float:
	return amount

## After a heal lands (`amount` = health restored, `overheal` = the wasted part).
func on_healed(_target: Node, _amount: float, _overheal: float, _tags: Array, _opts: Dictionary) -> void:
	pass

## Each time a heal-over-time ticks.
func on_hot_tick(_target: Node, _amount: float, _status) -> void:
	pass

## When a shield ends: `broken` = damage used it up, otherwise it faded.
func on_shield_ended(_target: Node, _status, _broken: bool, _remaining: float) -> void:
	pass

## The card text, with {TAG} markers.
func describe() -> String:
	return ""
