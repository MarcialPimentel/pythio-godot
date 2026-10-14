# autoload/systems/SpellSystem.gd
# Owns the spellbook and the whole cast flow:
#   request → checks (in round, mana, cooldown, not already casting)
#   → cast time (cast bar) → spend mana → apply effect → start cooldown → combo check.
# Players cast by hovering a fighter and pressing a spell key (Q/W/E/R/T),
# or by clicking a spell button and then clicking a fighter.
extends Node

signal spell_cast_started(spell: SpellData, target)
signal spell_cast_finished(spell: SpellData, target)
signal spell_cast_cancelled(spell: SpellData, target)
signal spell_cast_failed(spell: SpellData, reason: String)

@onready var effect_system = get_node("/root/EffectSystem")

## Keys for spellbook slots, in order. Rebind in Project Settings → Input Map
## (actions "spell_1" … "spell_5") once they exist there; these are the defaults.
const DEFAULT_SPELL_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T]
const COMBO_WINDOW = 1.5

var spells: Array[SpellData] = []        # the spellbook, in key order
var cooldowns: Dictionary = {}           # spell_id -> seconds remaining
var combo_tracker: Dictionary = {}       # target instance id -> {time, tags}

# Current cast
var is_casting: bool = false
var current_spell: SpellData = null
var current_target: Node = null
var cast_elapsed: float = 0.0

# Targeting
var hovered_target: Node = null          # fighter under the mouse
var last_target: Node = null             # last fighter clicked (used when nothing is hovered)


func _ready() -> void:
	_ensure_input_actions()
	load_all_spells()
	EventBus.spell_cast_requested.connect(request_cast)
	EventBus.target_hovered.connect(_on_target_hovered)
	EventBus.target_selected.connect(func(t): last_target = t)
	EventBus.round_ended.connect(func(_r): cancel_cast(); cooldowns.clear())


func load_all_spells() -> void:
	spells.clear()
	var dir = DirAccess.open("res://resources/spells/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Exported builds list resources as "name.tres.remap"
			var res_name = file_name.trim_suffix(".remap")
			if res_name.ends_with(".tres"):
				var spell = load("res://resources/spells/" + res_name)
				if spell is SpellData:
					spells.append(spell)
			file_name = dir.get_next()
	spells.sort_custom(func(a, b): return a.id < b.id)
	print("Loaded %d spells" % spells.size())


func _ensure_input_actions() -> void:
	for i in DEFAULT_SPELL_KEYS.size():
		var action := "spell_%d" % (i + 1)
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = DEFAULT_SPELL_KEYS[i]
		InputMap.action_add_event(action, ev)


func key_label_for_slot(slot: int) -> String:
	var action := "spell_%d" % (slot + 1)
	if not InputMap.has_action(action):
		return ""
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode else ev.keycode)
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	for i in spells.size():
		if event.is_action_pressed("spell_%d" % (i + 1)):
			var target = hovered_target if is_instance_valid(hovered_target) else last_target
			if is_instance_valid(target):
				request_cast(spells[i], target)
			else:
				spell_cast_failed.emit(spells[i], "no_target")
			get_viewport().set_input_as_handled()
			return


func _on_target_hovered(target: Node) -> void:
	hovered_target = target


# ── Casting ─────────────────────────────────────────────

func can_cast(spell: SpellData) -> bool:
	return GameManager.in_round and not is_casting \
		and not is_on_cooldown(spell.id) and GameManager.mana >= spell.mana_cost


func request_cast(spell: SpellData, target: Node) -> bool:
	if not spell or not is_instance_valid(target):
		return false
	if not GameManager.in_round:
		spell_cast_failed.emit(spell, "not_in_round"); return false
	if is_casting:
		spell_cast_failed.emit(spell, "busy"); return false
	if is_on_cooldown(spell.id):
		spell_cast_failed.emit(spell, "cooldown"); return false
	if GameManager.mana < spell.mana_cost:
		spell_cast_failed.emit(spell, "mana"); return false

	is_casting = true
	current_spell = spell
	current_target = target
	cast_elapsed = 0.0
	spell_cast_started.emit(spell, target)
	if spell.cast_time <= 0.0:
		_finish_cast()
	return true


func cast_progress() -> float:
	if not is_casting or not current_spell or current_spell.cast_time <= 0.0:
		return 0.0
	return clampf(cast_elapsed / current_spell.cast_time, 0.0, 1.0)


func cancel_cast() -> void:
	if not is_casting:
		return
	var spell = current_spell
	var target = current_target
	_clear_cast()
	spell_cast_cancelled.emit(spell, target)


func _process(delta: float) -> void:
	for id in cooldowns.keys():
		cooldowns[id] -= delta
		if cooldowns[id] <= 0.0:
			cooldowns.erase(id)

	if is_casting:
		if not is_instance_valid(current_target) or not GameManager.in_round:
			cancel_cast()
			return
		cast_elapsed += delta
		if cast_elapsed >= current_spell.cast_time:
			_finish_cast()


func _finish_cast() -> void:
	var spell = current_spell
	var target = current_target
	_clear_cast()
	if not is_instance_valid(target) or not GameManager.spend_mana(spell.mana_cost):
		spell_cast_cancelled.emit(spell, target)
		return
	effect_system.apply_effect(target, spell)
	if spell.cooldown > 0.0:
		cooldowns[spell.id] = spell.cooldown
	detect_combo(target, spell)
	spell_cast_finished.emit(spell, target)


func _clear_cast() -> void:
	is_casting = false
	current_spell = null
	current_target = null
	cast_elapsed = 0.0


# ── Cooldowns & combos ─────────────────────────────────

func get_spell_by_id(id: String) -> SpellData:
	for spell in spells:
		if spell.id == id:
			return spell
	return null


func is_on_cooldown(spell_id: String) -> bool:
	return cooldowns.get(spell_id, 0.0) > 0.0


func cooldown_remaining(spell_id: String) -> float:
	return maxf(0.0, cooldowns.get(spell_id, 0.0))


func detect_combo(target: Node, spell: SpellData) -> void:
	# Placeholder: combos become a real system in roadmap Phase 3.
	var now = Time.get_ticks_msec() / 1000.0
	var key = target.get_instance_id()
	if combo_tracker.has(key) and now - combo_tracker[key].time < COMBO_WINDOW:
		print("COMBO! on target ", target.index if "index" in target else "?", " with ", spell.id)
	combo_tracker[key] = {"time": now, "tags": spell.combo_tags}
