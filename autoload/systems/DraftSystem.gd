# autoload/systems/DraftSystem.gd
# Builds come from picks: a specialization at the start of a run, then a new spell
# (1 of N) on a schedule, until the spellbook is full. After that, only rank-ups are
# offered; once none are left, the build is complete. All of it is settings.
extends Node

signal spec_chosen(spec: SpecData)
signal spell_taken(spell: SpellData)
## Fired once per run when a pick round arrives and there's nothing left to offer.
signal build_complete

@export_group("Schedule")
## First spell pick happens after this round (so you're not alone with one spell for long).
@export var first_pick_after_round: int = 1
## …then every Nth round after that (owner, 2026-10-22: 2 → after rounds 1, 3, 5, 7 …).
@export var pick_every: int = 2

@export_group("Offers")
@export var offer_count: int = 3
## How many offers come from outside your school (splashing is where creative builds come from).
@export var off_school_offers: int = 1
## Caps: spells you cast (keys Q–R) and passive slots. At a cap only rank-ups of that kind
## are offered; with both full and no rank-ups left, the build is complete.
@export var spellbook_cap: int = 4
@export var passive_cap: int = 3
## Weights for the rest of the offers.
@export var own_school_weight: float = 3.0
@export var any_school_weight: float = 1.5
@export var rank_up_weight: float = 2.0

var specs: Array[SpecData] = []
var current_spec: SpecData = null
var _complete_announced := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_load_specs()


func _load_specs() -> void:
	specs.clear()
	var dir := DirAccess.open("res://resources/specs/")
	if not dir:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		var res_name := f.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			var s = load("res://resources/specs/" + res_name)
			if s is SpecData:
				specs.append(s)
		f = dir.get_next()
	specs.sort_custom(func(a, b): return a.order < b.order)


# ── Run start ──────────────────────────────────────────

func reset() -> void:
	current_spec = null
	_complete_announced = false
	var empty: Array[SpellData] = []
	SpellSystem.set_spellbook(empty)


func choose_spec(spec: SpecData) -> void:
	current_spec = spec
	var book: Array[SpellData] = []
	if spec.starter:
		book.append(spec.starter)
	SpellSystem.set_spellbook(book)
	spec_chosen.emit(spec)


func school() -> String:
	return current_spec.school if current_spec else ""


# ── Spell picks ────────────────────────────────────────

func is_pick_round(round_cleared: int) -> bool:
	if round_cleared <= 0:
		return false
	if round_cleared == first_pick_after_round:
		return true
	return pick_every > 0 and round_cleared > first_pick_after_round \
		and (round_cleared - first_pick_after_round) % pick_every == 0


## Offers for after `round_cleared` (empty if it isn't a pick round or nothing is left).
func offers_after_round(round_cleared: int) -> Array[SpellData]:
	var none: Array[SpellData] = []
	if not is_pick_round(round_cleared):
		return none
	var offers := make_offers()
	if offers.is_empty() and not _complete_announced:
		_complete_announced = true
		build_complete.emit()
	return offers


func is_full() -> bool:
	return spells_full() and passives_full()


func spells_full() -> bool:
	return SpellSystem.spells.size() >= mini(spellbook_cap, SpellSystem.SLOTS)


func passives_full() -> bool:
	return SpellSystem.passives.size() >= mini(passive_cap, SpellSystem.PASSIVE_SLOTS)


## Spells you could be offered right now: new spells (if there's room) and rank-ups.
func candidates() -> Dictionary:
	var fresh: Array[SpellData] = []
	var upgrades: Array[SpellData] = []
	for s in SpellSystem.library:
		var owned := SpellSystem.owned_rank(s.family())
		if owned > 0:
			if s.rank == owned + 1:
				upgrades.append(s)
			continue
		var no_room := passives_full() if s.is_passive() else spells_full()
		if s.rank != 1 or no_room or not requirements_met(s):
			continue
		fresh.append(s)
	return {"fresh": fresh, "upgrades": upgrades}


func requirements_met(spell: SpellData) -> bool:
	if spell.requires_tags.is_empty():
		return true
	for tag in spell.requires_tags:
		if SpellSystem.owns_tag(tag):
			return true
	return false


func make_offers() -> Array[SpellData]:
	var c := candidates()
	var pool: Array[SpellData] = []
	pool.append_array(c.fresh)
	pool.append_array(c.upgrades)
	var out: Array[SpellData] = []
	if pool.is_empty():
		return out
	var mine := school()
	# Off-school picks first (new spells from another school), then weighted for the rest.
	var off: Array = c.fresh.filter(func(s): return mine != "" and s.school != mine and s.school != "ANY")
	for i in mini(off_school_offers, off.size()):
		var pick := _weighted(off, func(s): return s.offer_weight)
		out.append(pick)
		off.erase(pick)
		pool.erase(pick)
	# The rest: your school, any-school spells and rank-ups; other schools only as a fallback.
	var home: Array = pool.filter(func(s): return mine == "" or s.school == mine or s.school == "ANY" or c.upgrades.has(s))
	while out.size() < offer_count and not pool.is_empty():
		var from: Array = home if not home.is_empty() else pool
		var pick := _weighted(from, _weight_for.bind(c.upgrades))
		out.append(pick)
		pool.erase(pick)
		home.erase(pick)
	_ensure_a_synergy(out, pool, off_school_offers)
	out.shuffle()
	return out


# ── Synergies (for hints on cards and "at least one offer combos") ──

## How `spell` connects to your spellbook:
## "with" = spells you own that it reacts to; "from" = spells you own that react to it.
func synergy(spell: SpellData) -> Dictionary:
	var with: Array[SpellData] = []
	var from: Array[SpellData] = []
	var tags: Array[String] = []
	for own in SpellSystem.all_owned():
		if own.family() == spell.family():
			continue
		for t in spell.reacts_to_tags:
			if own.tags.has(t) and not with.has(own):
				with.append(own)
				if not tags.has(t): tags.append(t)
		for t in own.reacts_to_tags:
			if spell.tags.has(t) and not from.has(own):
				from.append(own)
				if not tags.has(t): tags.append(t)
	return {"with": with, "from": from, "tags": tags}


func has_synergy(spell: SpellData) -> bool:
	var s := synergy(spell)
	return not s.with.is_empty() or not s.from.is_empty()


## If no offer combos with your spellbook but one could, swap one in (never the off-school slot).
func _ensure_a_synergy(out: Array[SpellData], pool: Array[SpellData], protected: int) -> void:
	if out.is_empty() or out.any(has_synergy):
		return
	var options := pool.filter(func(s): return not out.has(s) and has_synergy(s))
	if options.is_empty():
		return
	out[out.size() - 1 if out.size() > protected else 0] = options[rng.randi() % options.size()]


func _weight_for(s: SpellData, upgrades: Array) -> float:
	var w := s.offer_weight
	if upgrades.has(s):
		return w * rank_up_weight
	if s.school == school():
		return w * own_school_weight
	if s.school == "ANY":
		return w * any_school_weight
	return w


func _weighted(list: Array, weight: Callable) -> SpellData:
	var total := 0.0
	for s in list:
		total += maxf(0.0, weight.call(s))
	var roll := rng.randf() * total
	for s in list:
		roll -= maxf(0.0, weight.call(s))
		if roll <= 0.0:
			return s
	return list[list.size() - 1]


func take(spell: SpellData) -> void:
	SpellSystem.add_spell(spell)
	spell_taken.emit(spell)
