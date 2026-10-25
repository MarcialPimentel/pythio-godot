# autoload/systems/CleanseSystem.gd
# Cleanse (Phase F, owner 2026-10-25): a basic ability every run has, on its own key (F),
# separate from healing and from the bandage. Point at a fighter and press F: it removes
# Poison, Hex and Dread (never Bleed). Instant and free; it uses charges that refill one at
# a time during a round. The ability itself is a spell (resources/spells/cleanse.tres), so
# passives can react to the Cleanse tag; Purify is its rank-up, offered on spell picks.
extends Node

signal charges_changed(charges: int, max_charges: int)
signal cleanse_failed(reason: String)

## The spell on F at the start of every run.
@export var starter_id: String = "cleanse"
@export var key: Key = KEY_F

var charges: int = 0
var _refill := 0.0


func _ready() -> void:
	GameManager.show_spec_choice.connect(reset)
	EventBus.round_started.connect(func(_r): _refill_all())
	SpellSystem.spellbook_changed.connect(func(): charges = mini(charges, max_charges()); charges_changed.emit(charges, max_charges()))
	(func(): if SpellSystem.utility == null: reset()).call_deferred()


func spell() -> SpellData:
	return SpellSystem.utility


func max_charges() -> int:
	return spell().charges if spell() else 0


func charge_time() -> float:
	return spell().charge_time if spell() else 0.0


## 0..1 progress of the next charge (for the UI).
func refill_progress() -> float:
	return clampf(_refill / maxf(0.01, charge_time()), 0.0, 1.0) if charges < max_charges() else 1.0


## A new run: back to the basic Cleanse with full charges.
func reset() -> void:
	SpellSystem.utility = SpellSystem.get_library_spell(starter_id)
	_refill_all()


func _refill_all() -> void:
	charges = max_charges()
	_refill = 0.0
	charges_changed.emit(charges, max_charges())


func _process(delta: float) -> void:
	if not GameManager.in_round or charges >= max_charges():
		return
	_refill += delta
	if _refill >= charge_time():
		_refill = 0.0
		charges += 1
		charges_changed.emit(charges, max_charges())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or event.keycode != key:
		return
	if not GameManager.in_round:
		return
	get_viewport().set_input_as_handled()
	var t = SpellSystem.hovered_target if is_instance_valid(SpellSystem.hovered_target) else SpellSystem.last_target
	try_cleanse(t)


## Cleanses `t`. Instant: works while you cast (it doesn't interrupt), not while bandaging.
func try_cleanse(t: Node) -> bool:
	var reason := ""
	if not GameManager.in_round:
		reason = "not_in_round"
	elif not spell():
		reason = "no_cleanse"
	elif charges <= 0:
		reason = "no_charges"
	elif BandageSystem.is_channeling():
		reason = "busy"
	elif not is_instance_valid(t) or t.health_comp.is_dead:
		reason = "no_target"
	if reason != "":
		cleanse_failed.emit(reason)
		return false
	if charges >= max_charges():
		_refill = 0.0
	charges -= 1
	charges_changed.emit(charges, max_charges())
	EffectSystem.cast(spell(), t)
	return true


## True if pressing F on `t` would remove something (the counter glows violet).
func would_help(t: Node) -> bool:
	return is_instance_valid(t) and charges > 0 and not t.health_comp.is_dead \
		and not t.health_comp.debuffs(true).is_empty()
