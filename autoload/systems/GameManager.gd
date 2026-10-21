extends Node

signal round_started(round: int)
signal round_ended
signal game_over(round_reached: int, score: int)
signal show_party_choice
## Run start: pick a specialization (Mending / Bloom / Ward).
signal show_spec_choice
## Between rounds on a pick round: choose 1 of `offers` to add to the spellbook.
signal show_spell_pick(offers: Array, round_cleared: int)

var current_round: int = 1
var round_time: float
var in_round: bool = false
var score: int = 0
var high_score: int = 0
var mana: float = 100.0
var max_mana: float = 100.0
var regen_rate: float = 4.0
var last_run_won: bool = false
## Set when the F1 debug panel changes anything; such runs can't be posted online.
var debug_used: bool = false
var god_mode: bool = false

func _ready() -> void:
	load_high_score()

func new_game() -> void:
	current_round = 1
	score = 0
	debug_used = god_mode
	mana = DifficultySystem.max_mana_base
	max_mana = DifficultySystem.max_mana_base
	regen_rate = DifficultySystem.regen_rate_base
	in_round = false
	round_time = DifficultySystem.get_round_time(current_round)
	DraftSystem.reset()
	show_spec_choice.emit()


## After the specialization pick or a spell pick: on to choosing a contract.
func continue_to_contracts() -> void:
	show_party_choice.emit()

func end_round(success: bool) -> void:
	in_round = false
	EventBus.emit_signal("round_ended", current_round)
	
	if success:
		score += current_round * 100  # later tie to gold
	else:
		last_run_won = false
		game_over.emit(current_round, score)
		save_high_score()
		return
	
	current_round += 1
	if not DifficultySystem.is_endless() and current_round > DifficultySystem.total_rounds:
		last_run_won = true
		game_over.emit(DifficultySystem.total_rounds, score)
		save_high_score()
	else:
		round_time = DifficultySystem.get_round_time(current_round)
		max_mana = DifficultySystem.get_max_mana(current_round)
		# Carry leftover mana and top up part of the pool, rewarding efficient rounds.
		mana = minf(max_mana, mana + DifficultySystem.round_start_mana_refill * max_mana)
		_after_round(current_round - 1)


## A spell pick if this was a pick round (and there's something to offer), else contracts.
func _after_round(round_cleared: int) -> void:
	var offers := DraftSystem.offers_after_round(round_cleared)
	if offers.is_empty():
		show_party_choice.emit()
	else:
		show_spell_pick.emit(offers, round_cleared)

func spend_mana(cost: float) -> bool:
	if mana >= cost:
		mana -= cost
		return true
	return false

func regen_mana(delta: float) -> void:
	mana = minf(max_mana, mana + regen_rate * delta)

func save_high_score() -> void:
	if debug_used:
		return
	if score > high_score:
		high_score = score
		var config = ConfigFile.new()
		config.set_value("scores", "high", high_score)
		config.save("user://highscore.cfg")

func load_high_score() -> void:
	var config = ConfigFile.new()
	if config.load("user://highscore.cfg") == OK:
		high_score = config.get_value("scores", "high", 0)


# ── Debug panel helpers (F1) ───────────────────────────

func debug_skip_round() -> void:
	if not in_round:
		return
	debug_used = true
	end_round(true)


func debug_jump_to_round(n: int) -> void:
	debug_used = true
	var was_in_round := in_round
	in_round = false
	if was_in_round:
		EventBus.emit_signal("round_ended", current_round)
	current_round = maxi(1, n)
	round_time = DifficultySystem.get_round_time(current_round)
	max_mana = DifficultySystem.get_max_mana(current_round)
	mana = max_mana
	show_party_choice.emit()


func debug_add_mana(amount: float) -> void:
	debug_used = true
	mana = minf(max_mana, mana + amount)


## Debug: offer a spell pick right now (between rounds only).
func debug_offer_pick() -> void:
	if in_round:
		return
	debug_used = true
	var offers := DraftSystem.make_offers()
	if not offers.is_empty():
		show_spell_pick.emit(offers, current_round - 1)
