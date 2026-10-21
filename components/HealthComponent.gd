# components/HealthComponent.gd
# A fighter's health and the statuses on them (heal-over-time, shields, protection…).
# Damage is resolved in order: protection → shields (oldest first) → health → death save.
class_name HealthComponent
extends Node

@export var max_health: float = 100.0:
	set(value):
		max_health = value
		current_health = max_health

var current_health: float = 100.0:
	set(value):
		current_health = clampf(value, 0, max_health)
		health_changed.emit(current_health)

var is_dead: bool = false
## Debug god mode: damage still shows, but health never drops below 1.
var invulnerable: bool = false
var statuses: Array[Status] = []

## Total shield left across all shields.
var shield_amount: float:
	get:
		var total := 0.0
		for s in statuses:
			if s is ShieldStatus:
				total += s.remaining
		return total

## Longest heal-over-time left (0 if none).
var hot_time: float:
	get:
		var best := 0.0
		for s in statuses:
			if s is HotStatus:
				best = maxf(best, s.time_left)
		return best

signal health_changed(health: float)
signal shield_changed(amount: float)
signal statuses_changed
signal died


func fighter() -> Node:
	return get_parent()


# ── Statuses ───────────────────────────────────────────

func add_status(status: Status) -> void:
	if is_dead:
		return
	status.target = fighter()
	for s in statuses.duplicate():
		if s.key() == status.key():
			statuses.erase(s)   # recast refreshes rather than stacks (no end effects)
	statuses.append(status)
	_changed(status)


func remove_status(status: Status, expired: bool) -> void:
	if not statuses.has(status):
		return
	statuses.erase(status)
	status.on_end(self, expired)
	_changed(status)


func get_statuses(kind: String) -> Array[Status]:
	var out: Array[Status] = []
	for s in statuses:
		if s.kind == kind:
			out.append(s)
	return out


func has_status(kind: String) -> bool:
	for s in statuses:
		if s.kind == kind:
			return true
	return false


func tick_effects(delta: float) -> void:
	for s in statuses.duplicate():
		if not statuses.has(s):
			continue
		s.tick(self, delta)
		if s.time_left <= 0.0 and statuses.has(s):
			remove_status(s, true)


func _changed(status: Status) -> void:
	statuses_changed.emit()
	if status is ShieldStatus:
		shield_changed.emit(shield_amount)


# ── Damage & healing ───────────────────────────────────

## Returns {"prevented", "absorbed", "dealt"} so callers can show what happened.
func take_damage(amount: float) -> Dictionary:
	var result := {"prevented": 0.0, "absorbed": 0.0, "dealt": 0.0}
	if is_dead or amount <= 0.0:
		return result
	var incoming := amount
	for p in get_statuses("PROTECT"):
		incoming *= 1.0 - (p as ProtectStatus).reduction
	result.prevented = amount - incoming

	if incoming > 0.0:
		for s in get_statuses("SHIELD"):
			var shield := s as ShieldStatus
			var take := minf(incoming, shield.remaining)
			shield.remaining -= take
			incoming -= take
			result.absorbed += take
			if shield.remaining <= 0.0:
				remove_status(shield, false)   # broken
			if incoming <= 0.0:
				break
		if result.absorbed > 0.0:
			shield_changed.emit(shield_amount)
			EffectSystem.shield_absorbed(fighter(), result.absorbed)

	result.dealt = incoming
	if incoming <= 0.0:
		return result
	if invulnerable:
		current_health = maxf(1.0, current_health - incoming)
		return result
	if current_health - incoming <= 0.0:
		var saves := get_statuses("SAVE")
		if not saves.is_empty():
			current_health = 1.0
			var save := saves[0] as SaveStatus
			statuses.erase(save)
			_changed(save)
			EffectSystem.death_prevented(fighter(), save)
			return result
	current_health -= incoming
	if current_health <= 0.0 and not is_dead:
		is_dead = true
		statuses.clear()
		statuses_changed.emit()
		shield_changed.emit(0.0)
		died.emit()
	return result


## Restores health; returns how much was actually restored (the rest is overheal).
func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var before := current_health
	current_health += amount
	return current_health - before


# ── Shortcuts (debug panel, tests) ─────────────────────

func apply_shield(amount: float, duration: float) -> void:
	var s := ShieldStatus.new(amount, duration)
	s.label = "Shield"
	add_status(s)


func apply_hot(per_second: float, duration: float) -> void:
	var s := HotStatus.new(per_second, duration)
	s.label = "Heal-over-Time"
	add_status(s)
