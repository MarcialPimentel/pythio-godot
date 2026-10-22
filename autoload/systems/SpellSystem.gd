# autoload/systems/SpellSystem.gd
# Owns the spell library (every spell in the game), your spellbook (what you've picked,
# in key order) and the whole cast flow:
#   request → checks (in round, mana, cooldown, not already casting)
#   → cast time (cast bar) → spend mana → EffectSystem.cast → start cooldown.
# Combos are not decided here: spells react to each other through tags (see EffectSystem).
# Players cast by hovering a fighter and pressing a spell key (Q/W/E/R/T),
# or by clicking a spell button and then clicking a fighter.
extends Node

signal spell_cast_started(spell: SpellData, target)
signal spell_cast_finished(spell: SpellData, target)
signal spell_cast_cancelled(spell: SpellData, target)
signal spell_cast_failed(spell: SpellData, reason: String)
signal spellbook_changed

@onready var effect_system = get_node("/root/EffectSystem")

## Keys for spellbook slots, in order. Rebind in Project Settings → Input Map
## (actions "spell_1" … "spell_5") once they exist there; these are the defaults.
const DEFAULT_SPELL_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T]
## Spells you cast: keys Q–T.
const SLOTS := 5
## Passives (and later keystones) live in their own tray.
const PASSIVE_SLOTS := 3
## Spellbook before a specialization is picked (and in tests that skip the pick).
@export var default_spellbook_ids: PackedStringArray = ["flash_heal", "renew", "shield"]

var library: Array[SpellData] = []       # every spell in the game
var spells: Array[SpellData] = []        # spells you cast, in key order (Q–T)
var passives: Array[SpellData] = []      # passive tray
var cooldowns: Dictionary = {}           # spell_id -> seconds remaining

# Current cast
var is_casting: bool = false
var current_spell: SpellData = null
var current_target: Node = null
var cast_elapsed: float = 0.0
## Something else has your hands (a bandage channel): no casting until it ends.
var external_busy: bool = false

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
	library.clear()
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
					library.append(spell)
			file_name = dir.get_next()
	library.sort_custom(func(a, b): return a.id < b.id)
	print("Loaded %d spells" % library.size())
	set_spellbook_ids(default_spellbook_ids)


# ── Spellbook ──────────────────────────────────────────

func get_library_spell(id: String) -> SpellData:
	for spell in library:
		if spell.id == id:
			return spell
	return null


## Replaces everything you own; passives go to the tray, the rest to Q–T.
func set_spellbook(new_spells: Array[SpellData]) -> void:
	spells.clear()
	passives.clear()
	for s in new_spells:
		if s.is_passive():
			if passives.size() < PASSIVE_SLOTS:
				passives.append(s)
		elif spells.size() < SLOTS:
			spells.append(s)
	cooldowns.clear()
	spellbook_changed.emit()


## Everything you own: spells you cast, then passives.
func all_owned() -> Array[SpellData]:
	var out: Array[SpellData] = []
	out.append_array(spells)
	out.append_array(passives)
	return out


func set_spellbook_ids(ids: PackedStringArray) -> void:
	var list: Array[SpellData] = []
	for id in ids:
		var s := get_library_spell(id)
		if s:
			list.append(s)
	set_spellbook(list)


## Adds a spell. A higher rank of a spell you own replaces it in the same slot.
## Returns the slot used, or -1 if the spellbook is full.
func add_spell(spell: SpellData) -> int:
	var row := passives if spell.is_passive() else spells
	var cap := PASSIVE_SLOTS if spell.is_passive() else SLOTS
	for i in row.size():
		if row[i].family() == spell.family():
			row[i] = spell
			spellbook_changed.emit()
			return i
	if row.size() >= cap:
		return -1
	row.append(spell)
	spellbook_changed.emit()
	return row.size() - 1


func owns_tag(tag: String) -> bool:
	for s in all_owned():
		if s.tags.has(tag):
			return true
	return false


## The rank you own of a spell family (0 = not owned).
func owned_rank(family: String) -> int:
	for s in all_owned():
		if s.family() == family:
			return s.rank
	return 0


func passive_rules() -> Array[PassiveRule]:
	var out: Array[PassiveRule] = []
	for s in passives:
		if s.passive:
			out.append(s.passive)
	return out


## The passive spell that owns `rule` (for the tray to pulse), or null.
func passive_for_rule(rule: PassiveRule) -> SpellData:
	for s in passives:
		if s.passive == rule:
			return s
	return null


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
	return not spell.is_passive() and GameManager.in_round and not is_casting and not external_busy \
		and not is_on_cooldown(spell.id) and GameManager.mana >= spell.mana_cost


func request_cast(spell: SpellData, target: Node) -> bool:
	if not spell or not is_instance_valid(target) or spell.is_passive():
		return false
	if not GameManager.in_round:
		spell_cast_failed.emit(spell, "not_in_round"); return false
	if is_casting or external_busy:
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
	effect_system.cast(spell, target)
	if spell.cooldown > 0.0:
		cooldowns[spell.id] = spell.cooldown
	spell_cast_finished.emit(spell, target)


func _clear_cast() -> void:
	is_casting = false
	current_spell = null
	current_target = null
	cast_elapsed = 0.0


# ── Cooldowns ──────────────────────────────────────────

func get_spell_by_id(id: String) -> SpellData:
	for spell in spells:
		if spell.id == id:
			return spell
	return null


func is_on_cooldown(spell_id: String) -> bool:
	return cooldowns.get(spell_id, 0.0) > 0.0


func cooldown_remaining(spell_id: String) -> float:
	return maxf(0.0, cooldowns.get(spell_id, 0.0))
