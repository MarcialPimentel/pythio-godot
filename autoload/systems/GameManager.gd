extends Node

signal game_over(round_reached: int)
signal show_party_choice
## Run start: pick a specialization (Mending / Bloom / Ward).
signal show_spec_choice
## Between rounds on a pick round: choose 1 of `offers` to add to the spellbook.
signal show_spell_pick(offers: Array, round_cleared: int)

var current_round: int = 1
var round_time: float
var in_round: bool = false
var best_rounds: int = 0
var best_healing: int = 0
var mana: float = 100.0
var max_mana: float = 100.0
var regen_rate: float = 4.0
## Set when the F1 debug panel changes anything; such runs can't be posted online.
var debug_used: bool = false
## Exhaustion (battlefield rule): mana refills slower while this counts down.
var exhausted_time: float = 0.0
var exhausted_regen_factor: float = 1.0
var god_mode: bool = false
## Extra max mana earned this run (skipping a spell pick).
var bonus_max_mana: float = 0.0
## True during the first-time practice round (scenes/practice.gd): no timer, nothing counts.
var practice: bool = false

func _ready() -> void:
	load_high_score()
	(func(): TargetSystem.loss_condition.connect(_on_loss)).call_deferred()   # after every autoload exists


## The round clock and mana regen. Runs only in a round; stops while the game is paused.
func _process(delta: float) -> void:
	if not in_round:
		return
	round_time -= delta
	if round_time <= 0.0:
		round_time = 0.0
		end_round(true)
		return
	regen_mana(delta)


## A party was chosen on the Next party screen: spawn it and start the clock.
func start_round(contract: ContractData) -> void:
	TargetSystem.spawn_from_contract(contract)
	in_round = true
	EventBus.round_started.emit(current_round)


## Any fighter dying ends the run.
func _on_loss() -> void:
	if not in_round:
		return   # already ended this round
	SpellSystem.cancel_cast()
	end_round(false)


func new_game() -> void:
	current_round = 1
	debug_used = god_mode
	mana = DifficultySystem.max_mana_base
	max_mana = DifficultySystem.max_mana_base
	bonus_max_mana = 0.0
	regen_rate = DifficultySystem.regen_rate_base
	in_round = false
	exhausted_time = 0.0
	round_time = DifficultySystem.get_round_time(current_round)
	EventBus.run_started.emit()
	show_spec_choice.emit()


## The first-time practice round: round-1 mana and damage, no timer, nothing saved or posted.
func start_practice() -> void:
	practice = true
	current_round = 1
	debug_used = true   # belt and braces: practice can never reach the leaderboard
	mana = DifficultySystem.max_mana_base
	max_mana = DifficultySystem.max_mana_base
	bonus_max_mana = 0.0
	regen_rate = DifficultySystem.regen_rate_base
	exhausted_time = 0.0
	round_time = 1.0e9
	in_round = false
	EventBus.run_started.emit()


func end_practice() -> void:
	practice = false
	if in_round:
		in_round = false
		EventBus.emit_signal("round_ended", current_round)


## Leaves the current run without a game over (pause menu → Restart / Quit to title).
## Ending the round makes every system drop its casts, bursts, bandage and boss state.
func abandon_run() -> void:
	if in_round:
		in_round = false
		EventBus.emit_signal("round_ended", current_round)


## After the specialization pick or a spell pick: on to choosing a contract.
func continue_to_contracts() -> void:
	show_party_choice.emit()

func end_round(success: bool) -> void:
	in_round = false
	EventBus.emit_signal("round_ended", current_round)

	if not success:
		save_high_score()
		game_over.emit(current_round)
		return
	EventBus.round_cleared.emit(current_round)

	current_round += 1
	round_time = DifficultySystem.get_round_time(current_round)
	max_mana = DifficultySystem.get_max_mana(current_round) + bonus_max_mana
	regen_rate = DifficultySystem.get_regen_rate(current_round)
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

## Permanent extra max mana for the rest of the run (and the same amount right now).
func add_bonus_max_mana(amount: float) -> void:
	bonus_max_mana += amount
	max_mana += amount
	mana = minf(max_mana, mana + amount)


func spend_mana(cost: float) -> bool:
	if mana >= cost:
		mana -= cost
		if cost > 0.0:
			EffectSystem.mana_spent()
		return true
	return false

func regen_mana(delta: float) -> void:
	var rate := regen_rate
	if exhausted_time > 0.0:
		exhausted_time -= delta
		rate *= exhausted_regen_factor
	mana = minf(max_mana, mana + rate * delta)


## Exhaustion: mana refills at `factor` speed for `seconds`.
func exhaust(seconds: float, factor: float) -> void:
	exhausted_time = maxf(exhausted_time, seconds)
	exhausted_regen_factor = factor
	EventBus.rule_triggered.emit("exhausted", null)

## Best run on this device: most rounds survived, then most effective healing.
func save_high_score() -> void:
	if debug_used:
		return
	var r := rounds_survived()
	var h := RunStats.effective_healing()
	if r > best_rounds or (r == best_rounds and h > best_healing):
		best_rounds = r
		best_healing = h
		var config = ConfigFile.new()
		config.set_value("best", "rounds", best_rounds)
		config.set_value("best", "healing", best_healing)
		config.save("user://highscore.cfg")

func load_high_score() -> void:
	var config = ConfigFile.new()
	if config.load("user://highscore.cfg") == OK:
		best_rounds = config.get_value("best", "rounds", 0)
		best_healing = config.get_value("best", "healing", 0)


## Rounds fully survived in the current/last run.
func rounds_survived() -> int:
	return maxi(0, current_round - 1)


func best_text() -> String:
	if best_rounds <= 0 and best_healing <= 0:
		return "Best: no runs yet"
	return "Best: %d rounds · %s healing" % [best_rounds, RunStats.fmt(best_healing)]


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
	max_mana = DifficultySystem.get_max_mana(current_round) + bonus_max_mana
	regen_rate = DifficultySystem.get_regen_rate(current_round)
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
