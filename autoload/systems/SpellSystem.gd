# autoload/systems/SpellSystem.gd
extends Node

signal spell_cast_started(spell: SpellData, target)
signal spell_cast_finished(spell: SpellData, target)

@onready var effect_system = get_node("/root/EffectSystem")

var spells: Array[SpellData] = []
var cooldowns: Dictionary = {}  # spell_id -> remaining time

var combo_tracker: Dictionary = {}  # target_index -> last_cast_time + spell_tag

const COMBO_WINDOW = 1.5

func _ready():
	load_all_spells()
	# Start cooldown timer if needed

func load_all_spells():
	spells.clear()
	var dir = DirAccess.open("res://resources/spells/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var spell = load("res://resources/spells/" + file_name)
				if spell is SpellData:
					spells.append(spell)
			file_name = dir.get_next()
		print("Loaded %d spells" % spells.size())

func cast_spell(spell_id: String, target_index: int) -> bool:
	var spell = get_spell_by_id(spell_id)
	if not spell:
		return false
	
	# Mana check (GameManager or PlayerMana)
	if not has_enough_mana(spell.mana_cost):
		return false
	
	# Cooldown check
	if is_on_cooldown(spell_id):
		return false
	
	var target = TargetSystem.get_target_by_index(target_index)
	if not target:
		return false
	
	# Start cast
	spell_cast_started.emit(spell, target)
	
	# Apply effect
	effect_system.apply_effect(target, spell)
	
	# Start cooldown
	start_cooldown(spell_id, spell.cast_time if spell.cast_time > 0 else 0.5)
	
	# Combo detection
	detect_combo(target_index, spell)
	
	# Consume mana
	consume_mana(spell.mana_cost)
	
	spell_cast_finished.emit(spell, target)
	return true

func get_spell_by_id(id: String) -> SpellData:
	for spell in spells:
		if spell.id == id:
			return spell
	return null

func is_on_cooldown(spell_id: String) -> bool:
	return cooldowns.has(spell_id) and cooldowns[spell_id] > 0

func start_cooldown(spell_id: String, duration: float):
	cooldowns[spell_id] = duration
	# In _process you would decrement, or use Timer

func detect_combo(target_index: int, spell: SpellData):
	var now = Time.get_ticks_msec() / 1000.0
	var key = str(target_index)
	if combo_tracker.has(key):
		var last = combo_tracker[key]
		if now - last.time < COMBO_WINDOW:
			# Combo!
			print("COMBO! on target ", target_index, " with ", spell.id)
			# Trigger bonus, quip, VFX etc.
	combo_tracker[key] = {"time": now, "tag": spell.combo_tags}

# Placeholder mana functions - connect to your mana system
func has_enough_mana(cost: float) -> bool:
	# return GameManager.current_mana >= cost
	return true

func consume_mana(cost: float):
	pass # GameManager.current_mana -= cost
