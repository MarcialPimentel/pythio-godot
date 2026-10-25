# resources/spells/passives/PassiveRule.gd
# What a passive spell does. The effect system calls these hooks on every passive in the
# spellbook; a passive overrides only the ones it cares about.
class_name PassiveRule
extends Resource

## For battlefield rules: an id passives can cancel, and a name shown on screen.
@export var rule_id: String = ""
@export var rule_name: String = ""
## Battlefield rules this passive cancels (its "mirror"), e.g. ["diminishing_shields"].
@export var negates: PackedStringArray = []

## Change the size of a heal before it lands. `opts` carries flags such as "echo".
func modify_heal(amount: float, _target: Node, _tags: Array, _opts: Dictionary) -> float:
	return amount

## After a heal lands (`amount` = health restored, `overheal` = the wasted part).
func on_healed(_target: Node, _amount: float, _overheal: float, _tags: Array, _opts: Dictionary) -> void:
	pass

## Change the size of a shield before it's put on `target`.
func modify_shield(amount: float, _target: Node, _spell: SpellData) -> float:
	return amount

## After a cast leaves you too little mana for any of your spells.
func on_mana_empty() -> void:
	pass

## Each time a heal-over-time ticks.
func on_hot_tick(_target: Node, _amount: float, _status) -> void:
	pass

## When a shield ends: `broken` = damage used it up, otherwise it faded.
func on_shield_ended(_target: Node, _status, _broken: bool, _remaining: float) -> void:
	pass

## True if casting `spell` on `target` right now would make this passive fire (glow).
func would_combo(_spell: SpellData, _target: Node) -> bool:
	return false

## After you finish casting `spell` on `target`.
func on_cast(_spell: SpellData, _target: Node) -> void:
	pass

## After a Cleanse removed `count` debuffs from `target` (Phase F).
func on_cleansed(_target: Node, _count: int, _spell: SpellData) -> void:
	pass

## Forget per-run counters and cooldowns (called when a new run starts).
func reset_state() -> void:
	pass

## The card text, with {TAG} markers.
func describe() -> String:
	return ""
