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

var shield_amount: float = 0.0:
	set(value):
		shield_amount = maxf(value, 0)
		shield_changed.emit(shield_amount)

var shield_time: float = 0.0
var hot_amount: float = 0.0
var hot_time: float = 0.0

signal health_changed(health: float)
signal shield_changed(amount: float)
signal died

func take_damage(amount: float) -> void:
	if shield_amount > 0:
		var absorbed = minf(amount, shield_amount)
		shield_amount -= absorbed
		amount -= absorbed
		shield_changed.emit(shield_amount)
	current_health -= amount
	health_changed.emit(current_health)
	if current_health <= 0:
		died.emit()

func heal(amount: float) -> void:
	current_health += amount
	health_changed.emit(current_health)

func apply_hot(amount: float, duration: float) -> void:
	hot_amount = amount
	hot_time = duration

func apply_shield(amount: float, duration: float) -> void:
	shield_amount = maxf(shield_amount, amount)
	shield_time = maxf(shield_time, duration)

func tick_effects(delta: float) -> void:
	if hot_time > 0:
		heal(hot_amount * delta)
		hot_time -= delta
		if hot_time <= 0:
			hot_amount = 0
	if shield_time > 0:
		shield_time -= delta
		if shield_time <= 0:
			shield_amount = 0
			shield_changed.emit(0)
