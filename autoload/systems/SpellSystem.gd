extends Node

signal cast_started
signal cast_finished(spell: Spell)
signal selected_spell_changed

var spells: Array[Spell] = []
var selected_spell: Spell:
	set(value):
		selected_spell = value
		selected_spell_changed.emit()

var is_casting: bool = false
var cast_progress: float = 0.0
var current_spell: Spell
var current_target: Node

func _ready() -> void:
	spells = [
		load("res://resources/spells/flash_heal.tres") as Spell,
		load("res://resources/spells/renew.tres") as Spell,
		load("res://resources/spells/shield.tres") as Spell
	]
	EventBus.spell_cast_requested.connect(_on_spell_cast_requested)

func _on_spell_cast_requested(spell: Spell, target: Node) -> void:
	if try_cast(spell, target):
		print("Cast started: ", spell.display_name)
	else:
		print("Cast failed: ", spell.display_name)

func try_cast(spell: Spell, target: Node) -> bool:
	if is_casting:
		return false
	if not GameManager.spend_mana(spell.mana_cost):
		return false
	is_casting = true
	cast_progress = 0.0
	current_spell = spell
	current_target = target
	cast_started.emit()
	return true

func _process(delta: float) -> void:
	if not is_casting:
		return
	cast_progress += delta
	if cast_progress >= current_spell.cast_time:
		finish_cast()

# In SpellSystem.gd – replace the line in finish_cast():
func finish_cast() -> void:
	is_casting = false
	
	var hc = current_target.get_node("HealthComponent") as HealthComponent
	if not hc:
		print("No HealthComponent on target – cast failed")
		cast_finished.emit(current_spell)
		return
	
	var success = true
	match current_spell.effect_type:
		"instant_heal":
			hc.heal(current_spell.effect_value)
		"hot":
			var boost = 1.25 if hc.shield_amount > 0 else 1.0
			hc.apply_hot(current_spell.effect_value * boost, current_spell.effect_duration)
		"shield":
			hc.apply_shield(current_spell.effect_value, current_spell.effect_duration)
		_:
			success = false
			print("Unknown effect type:", current_spell.effect_type)
	
	EventBus.spell_cast_completed.emit(current_spell, current_target, success)
	cast_finished.emit(current_spell)
