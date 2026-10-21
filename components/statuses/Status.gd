# components/statuses/Status.gd
# Something living on a fighter for a while: a heal-over-time, a shield, a delayed heal…
# HealthComponent ticks statuses and removes them when time runs out.
class_name Status
extends RefCounted

## HOT, SHIELD, PROTECT, DELAYED, ECHO or SAVE — what kind of thing this is.
var kind: String = ""
## Shown on the fighter (e.g. "Renew").
var label: String = ""
## The spell that made it (may be null for debug/test statuses).
var spell: SpellData = null
var tags: Array = []
var duration: float = 0.0
var time_left: float = 0.0
## The fighter it's on (set by HealthComponent.add_status).
var target: Node = null


## Statuses with the same key replace each other (recasting refreshes instead of stacking).
func key() -> String:
	return "%s:%s" % [kind, spell.id if spell else label]


func tick(_hc: HealthComponent, delta: float) -> void:
	time_left -= delta


## Called once when the status is removed. `expired` = its time ran out.
func on_end(_hc: HealthComponent, _expired: bool) -> void:
	pass
