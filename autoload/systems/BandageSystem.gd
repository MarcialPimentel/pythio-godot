# autoload/systems/BandageSystem.gd
# Bandages: a panic button on its own resource. Hover a fighter and press Space to channel
# a heal; you can't cast while channelling. A few charges, refilled slowly between rounds.
extends Node

signal charges_changed(charges: int, max_charges: int)
signal channel_started(target: Node, duration: float)
signal channel_ended(target: Node, completed: bool)
signal bandage_failed(reason: String)

@export var max_charges: int = 3
@export var start_charges: int = 3
## Gain one charge after every Nth round cleared.
@export var gain_every_rounds: int = 2
@export var heal_total: float = 40.0
@export var channel_time: float = 2.5

var charges: int = 3
var target: Node = null
var elapsed: float = 0.0
var _pending_float := 0.0
var _float_timer := 0.0


func _ready() -> void:
	EventBus.round_cleared.connect(_on_round_cleared)
	EventBus.round_ended.connect(func(_r): _end(false))
	GameManager.show_spec_choice.connect(reset)


func reset() -> void:
	_end(false)
	charges = start_charges
	charges_changed.emit(charges, max_charges)


func is_channeling() -> bool:
	return target != null


func progress() -> float:
	return clampf(elapsed / maxf(0.01, channel_time), 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or event.keycode != KEY_SPACE:
		return
	if not GameManager.in_round:
		return
	get_viewport().set_input_as_handled()
	var t = SpellSystem.hovered_target if is_instance_valid(SpellSystem.hovered_target) else SpellSystem.last_target
	try_bandage(t)


func try_bandage(t: Node) -> bool:
	var reason := ""
	if not GameManager.in_round:
		reason = "not_in_round"
	elif charges <= 0:
		reason = "no_charges"
	elif is_channeling() or SpellSystem.is_casting:
		reason = "busy"
	elif not is_instance_valid(t) or t.health_comp.is_dead:
		reason = "no_target"
	if reason != "":
		bandage_failed.emit(reason)
		return false
	charges -= 1
	charges_changed.emit(charges, max_charges)
	target = t
	elapsed = 0.0
	_pending_float = 0.0
	_float_timer = 0.0
	SpellSystem.external_busy = true
	channel_started.emit(t, channel_time)
	return true


func _process(delta: float) -> void:
	if not is_channeling():
		return
	if not is_instance_valid(target) or target.health_comp.is_dead or not GameManager.in_round:
		_end(false)
		return
	var step := minf(delta, channel_time - elapsed)
	var amount := heal_total * step / channel_time
	EffectSystem.heal(target, amount, null, [], {"quiet": true, "no_echo": true})
	_pending_float += amount
	_float_timer += step
	elapsed += step
	if _float_timer >= 0.5 or elapsed >= channel_time:
		EffectSystem.effect_applied.emit("hot_tick", target, _pending_float, "")
		_pending_float = 0.0
		_float_timer = 0.0
	if elapsed >= channel_time:
		_end(true)


func _end(completed: bool) -> void:
	if not is_channeling():
		return
	var t := target
	target = null
	SpellSystem.external_busy = false
	channel_ended.emit(t, completed)


func _on_round_cleared(round_num: int) -> void:
	if gain_every_rounds > 0 and round_num % gain_every_rounds == 0 and charges < max_charges:
		charges += 1
		charges_changed.emit(charges, max_charges)
