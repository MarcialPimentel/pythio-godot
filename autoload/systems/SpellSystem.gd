# autoload/systems/SpellSystem.gd
extends Node

signal spell_cast_started(spell_id: String, target_index: int)
signal spell_cast_finished(spell_id: String, success: bool)

@onready var effect_system = get_node("/root/EffectSystem")

var spells: Array[SpellData] = []
var cooldowns: Dictionary = {}  # spell_id -> remaining time
var combo_tracker: Dictionary = {}  # target_index -> last_cast_time + spell_tag

const COMBO_WINDOW: float = 1.5

func _ready():
	load_all_spells()

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
		print("Loaded ", spells.size(), " spells")

func cast_spell(spell_id: String, target_index: int) -> bool:
	var spell = get_spell_by_id(spell_id)
	if not spell:
		return false
	
	# Mana check (assume GameManager or ManaSystem)
	if not has_sufficient_mana(spell.mana_cost):
		EventBus.emit_signal("mana_insufficient")
		return false
	
	# Cooldown check
	if cooldowns.has(spell_id) and cooldowns[spell_id] > 0:
		return false
	
	emit_signal("spell_cast_started", spell_id, target_index)
	
	# Apply via EffectSystem
	var target = TargetSystem.get_target_by_index(target_index)
	if target:
		effect_system.apply_effect(spell, target)
		
		# Combo detection
		check_for_combo(target_index, spell)
		
		# Start cooldown
		cooldowns[spell_id] = 5.0  # example cooldown
		
		# Mana deduction
		deduct_mana(spell.mana_cost)
		
		emit_signal("spell_cast_finished", spell_id, true)
		return true
	
	emit_signal("spell_cast_finished", spell_id, false)
	return false

func get_spell_by_id(id: String) -> SpellData:
	for s in spells:
		if s.id == id:
			return s
	return null

func check_for_combo(target_index: int, spell: SpellData):
	var now = Time.get_ticks_msec() / 1000.0
	if not combo_tracker.has(target_index):
		combo_tracker[target_index] = {"time": now, "tags": spell.combo_tags}
		return
	
	var last = combo_tracker[target_index]
	if now - last.time < COMBO_WINDOW and last.tags.any(func(t): return t in spell.combo_tags):
		# Bonus combo effect!
		print("COMBO! on target ", target_index)
		EventBus.emit_signal("combo_triggered", spell)
	
	combo_tracker[target_index] = {"time": now, "tags": spell.combo_tags}

# Placeholder mana functions - connect to your mana system
func has_sufficient_mana(cost: float) -> bool:
	return true  # replace with real check

func deduct_mana(cost: float):
	pass  # replace with real deduction

func _process(delta: float):
	for id in cooldowns.keys():
		if cooldowns[id] > 0:
			cooldowns[id] -= delta
