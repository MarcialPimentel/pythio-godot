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

func finish_cast() -> void:
	is_casting = false
	TargetSystem.apply_spell(current_spell, current_target)
	cast_finished.emit(current_spell)
