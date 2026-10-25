# autoload/systems/DebuffSystem.gd
# Phase F (owner, 2026-10-25): from round 6, fighters get debuffs on their own timer, with
# no warning (bursts are the "see it coming" threat; debuffs are the "react" threat).
# Four kinds, each with its own answer (see components/statuses/DebuffStatus.gd):
#   Poison → Cleanse (F) · Bleed (opens a wound) → heal above 80% or bandage · Hex → Cleanse or shields ·
#   Dread → Cleanse, or keep the fighter above the line.
# Every number is in DifficultySystem ("Debuffs (Phase F)").
extends Node

## The first time each kind shows up in a run (Pythio says what to do).
signal first_seen(debuff: String)

var _timer := 0.0
var _interval := 0.0
var _seen := {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	EventBus.round_started.connect(_on_round_started)
	GameManager.show_spec_choice.connect(func(): _seen.clear())


func _on_round_started(round_num: int) -> void:
	_interval = DifficultySystem.get_debuff_interval(round_num)
	_timer = _interval * 0.5   # the first debuff comes after half an interval


func _process(delta: float) -> void:
	if not GameManager.in_round or GameManager.practice or _interval <= 0.0:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _interval
	apply_random()


## Puts a random debuff on a random fighter who can take it. Returns the status, or null.
func apply_random() -> DebuffStatus:
	var kinds: Array = []
	var weights: Array = []
	for k in DifficultySystem.debuff_weights:
		if DifficultySystem.debuff_weights[k] > 0.0:
			kinds.append(k)
			weights.append(DifficultySystem.debuff_weights[k])
	if kinds.is_empty():
		return null
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	var kind: String = kinds[kinds.size() - 1]
	for i in kinds.size():
		roll -= weights[i]
		if roll <= 0.0:
			kind = kinds[i]
			break
	var options := TargetSystem.targets.filter(func(t): return is_instance_valid(t) and can_take(t, kind))
	if options.is_empty():
		return null
	return apply(options[rng.randi() % options.size()], kind)


## Never the Baron (his fight has its own phases); never a fighter who can't take it.
func can_take(t: Node, kind: String) -> bool:
	var hc: HealthComponent = t.health_comp
	if hc.is_dead or t.is_boss or hc.has_status("IMMUNE"):
		return false
	var on := hc.get_debuff(kind)
	if on and not (kind == "POISON" and on.stacks < on.max_stacks):
		return false
	# Dread needs room: never on a fighter already near the line (that would be a free kill).
	if kind == "DREAD" and hc.current_health < hc.max_health * DifficultySystem.dread_threshold * 1.6:
		return false
	return true


## Builds a `kind` debuff with this round's numbers and puts it on `t`.
func apply(t: Node, kind: String) -> DebuffStatus:
	var D := DifficultySystem
	var scale := D.get_debuff_scale(GameManager.current_round)
	var d: DebuffStatus
	match kind:
		"POISON":
			d = DebuffStatus.new("POISON", D.poison_time)
			d.dps = D.poison_dps * scale
			d.max_stacks = D.poison_max_stacks
		"BLEED":
			d = DebuffStatus.new("BLEED", D.bleed_time)
			d.dps = D.bleed_dps * scale
			d.end_above = D.bleed_end_above
		"HEX":
			d = DebuffStatus.new("HEX", D.hex_time)
			d.heal_taken = D.hex_heal_taken
		"DREAD":
			d = DebuffStatus.new("DREAD", D.dread_time)
			d.threshold = t.health_comp.max_health * D.dread_threshold
		_:
			return null
	if kind == "BLEED":
		var hc: HealthComponent = t.health_comp
		var wound := hc.current_health - hc.max_health * D.bleed_wound_to
		if wound > 0.0:
			hc.take_damage(wound)   # the wound that bleeds
	EffectSystem.add_debuff(t, d)
	if not _seen.has(kind):
		_seen[kind] = true
		first_seen.emit(kind)
	return t.health_comp.get_debuff(kind)
