# autoload/systems/DraftSystem.gd
# Builds come from picks: a starting spell, then picks on a schedule. Phase E (owner,
# 2026-10-25): ordinary pick rounds offer spells; beating the Crimson Baron offers a passive
# (1 of 3, leaning toward the tags you own), so passives are the rare, bigger moments.
# When a row is full, picks offer swaps and rank-ups. All of it is settings.
extends Node

signal spec_chosen(spec: SpecData)
signal spell_taken(spell: SpellData)
## Fired once per run when a pick round arrives and there's nothing left to offer.
signal build_complete
signal skipped

@export_group("Schedule")
## First spell pick happens after this round (so you're not alone with one spell for long).
@export var first_pick_after_round: int = 1
## …then every Nth round after that (owner, 2026-10-22: 2 → after rounds 1, 3, 5, 7 …).
@export var pick_every: int = 2
## Phase E (owner, 2026-10-25): spell picks on pick rounds, a passive pick after each Baron.
## Off = the Phase D rule (any pick can offer spells or passives).
@export var passives_from_baron: bool = true

@export_group("Offers")
@export var offer_count: int = 3
## How many offers come from outside your school (splashing is where creative builds come from).
@export var off_school_offers: int = 1
## Caps: spells you cast (keys Q–R) and passive slots. At a cap only rank-ups of that kind
## are offered; with both full and no rank-ups left, the build is complete.
@export var spellbook_cap: int = 4
@export var passive_cap: int = 3
## Owner, 2026-10-22 (proposed by Claude): when a row is full, new spells are still offered
## and taking one replaces a spell you choose. Off = the old rule (rank-ups, then build complete).
@export var swap_when_full: bool = true
## Skipping a pick gives this much extra max mana for the rest of the run.
@export var skip_bonus_max_mana: float = 10.0
## Weights for the rest of the offers.
@export var own_school_weight: float = 3.0
@export var any_school_weight: float = 1.5
@export var rank_up_weight: float = 2.0
## Baron passive picks lean harder toward your tags: they should make your spells better.
## Each owned tag a passive reacts to or shares (up to 2) adds this much (2.0 → ×3, ×5).
@export var passive_tag_weight: float = 2.0
## Offers lean toward the tags you already own (#68): each owned tag a spell shares or
## reacts to (up to 2) adds this much to its weight (1.0 → ×2 for one, ×3 for two).
## Keeps a big pool from burying your combo pieces. 0 = off.
@export var tag_affinity_weight: float = 1.0

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
	return pick_kind(round_cleared) != ""


## What the pick after `round_cleared` offers: "spell", "passive" (after a Baron) or "" (none).
func pick_kind(round_cleared: int) -> String:
	if round_cleared <= 0:
		return ""
	if passives_from_baron and DifficultySystem.is_boss_round(round_cleared):
		return "passive"
	var scheduled := round_cleared == first_pick_after_round or (pick_every > 0
		and round_cleared > first_pick_after_round
		and (round_cleared - first_pick_after_round) % pick_every == 0)
	if not scheduled:
		return ""
	return "spell" if passives_from_baron else "any"


## Offers for after `round_cleared` (empty if it isn't a pick round or nothing is left).
## A Baron pick with no passive left to offer falls back to a spell pick.
func offers_after_round(round_cleared: int) -> Array[SpellData]:
	var none: Array[SpellData] = []
	var kind := pick_kind(round_cleared)
	if kind == "":
		return none
	var offers := make_offers(kind)
	if offers.is_empty() and kind == "passive":
		offers = make_offers("spell")
	var settled: bool = is_full() and candidates().upgrades.is_empty()
	if (offers.is_empty() or settled) and not _complete_announced:
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
func candidates(kind: String = "any") -> Dictionary:
	var fresh: Array[SpellData] = []
	var upgrades: Array[SpellData] = []
	for s in SpellSystem.library:
		if (kind == "spell" and s.is_passive()) or (kind == "passive" and not s.is_passive()):
			continue
		var owned := SpellSystem.owned_rank(s.family())
		if owned > 0:
			if s.rank == owned + 1:
				upgrades.append(s)
			continue
		var no_room := passives_full() if s.is_passive() else spells_full()
		if s.rank != 1 or (no_room and not swap_when_full) or not requirements_met(s):
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


## `kind`: "spell" (spells you cast), "passive" or "any" (both, the Phase D rule).
func make_offers(kind: String = "spell") -> Array[SpellData]:
	if not passives_from_baron and kind == "spell":
		kind = "any"
	var c := candidates(kind)
	var pool: Array[SpellData] = []
	pool.append_array(c.fresh)
	pool.append_array(c.upgrades)
	var out: Array[SpellData] = []
	if pool.is_empty():
		return out
	var mine := school()
	# Off-school picks first (new spells from another school), then weighted for the rest.
	var off: Array = c.fresh.filter(func(s): return mine != "" and s.school != mine and s.school != "ANY")
	# Baron passive picks: no off-school slot, and a strong lean toward your tags.
	var off_n := 0 if kind == "passive" else off_school_offers
	var affinity := (func(s): return s.offer_weight * tag_affinity(s, passive_tag_weight)) if kind == "passive" \
		else (func(s): return s.offer_weight * tag_affinity(s))
	for i in mini(off_n, off.size()):
		var pick := _weighted(off, affinity)
		out.append(pick)
		off.erase(pick)
		pool.erase(pick)
	# The rest: your school, any-school spells and rank-ups; other schools only as a fallback.
	var home: Array = pool.filter(func(s): return mine == "" or s.school == mine or s.school == "ANY" or c.upgrades.has(s))
	while out.size() < offer_count and not pool.is_empty():
		var from: Array = home if not home.is_empty() else pool
		var pick := _weighted(from, affinity if kind == "passive" else _weight_for.bind(c.upgrades))
		out.append(pick)
		pool.erase(pick)
		home.erase(pick)
	_ensure_a_synergy(out, pool, off_n)
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
	w *= tag_affinity(s)
	if s.school == school():
		return w * own_school_weight
	if s.school == "ANY":
		return w * any_school_weight
	return w


## How strongly `spell` connects to the tags you own: 1 (none) up to 1 + 2 × tag_affinity_weight.
func tag_affinity(spell: SpellData, per_tag: float = -1.0) -> float:
	if per_tag < 0.0:
		per_tag = tag_affinity_weight
	var owned := {}
	for own in SpellSystem.all_owned():
		for t in own.tags: owned[t] = true
		for t in own.reacts_to_tags: owned[t] = true
	var shared := {}
	for t in spell.tags + spell.reacts_to_tags:
		if owned.has(t): shared[t] = true
	return 1.0 + per_tag * mini(2, shared.size())


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


## True if taking `spell` means giving up one you own (its row is full and it isn't a rank-up).
func needs_swap(spell: SpellData) -> bool:
	if SpellSystem.owned_rank(spell.family()) > 0:
		return false
	return passives_full() if spell.is_passive() else spells_full()


## Takes `spell` in place of `old` (same slot, same key).
func swap(old: SpellData, spell: SpellData) -> void:
	SpellSystem.replace_spell(old, spell)
	spell_taken.emit(spell)


## Debug (F1): put any spell in your build right now. A rank replaces its lower rank; with a
## full row it replaces the last slot. Marks the run as debug (no leaderboard).
func debug_take(spell: SpellData) -> void:
	GameManager.debug_used = true
	if needs_swap(spell):
		var row: Array = SpellSystem.passives if spell.is_passive() else SpellSystem.spells
		SpellSystem.replace_spell(row[row.size() - 1], spell)
	else:
		SpellSystem.add_spell(spell)
	spell_taken.emit(spell)


## Debug (F1): back to just your school's starter spell.
func debug_reset_build() -> void:
	GameManager.debug_used = true
	var book: Array[SpellData] = []
	if current_spec and current_spec.starter:
		book.append(current_spec.starter)
	SpellSystem.set_spellbook(book)


## Passes on a pick: a little extra max mana instead.
func skip() -> void:
	GameManager.add_bonus_max_mana(skip_bonus_max_mana)
	skipped.emit()
