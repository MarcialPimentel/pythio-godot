extends Node

signal round_started(round: int)
signal round_ended
signal game_over(round_reached: int, score: int)
signal show_party_choice

var current_round: int = 1
var round_time: float = 15.0
var in_round: bool = false
var score: int = 0
var high_score: int = 0
var mana: float = 100.0
var max_mana: float = 100.0
var regen_rate: float = 4.0

func _ready() -> void:
	load_high_score()

func new_game() -> void:
	current_round = 1
	score = 0
	mana = DifficultySystem.max_mana_base
	max_mana = DifficultySystem.max_mana_base
	in_round = false
	round_time = DifficultySystem.round_time_base
	show_party_choice.emit()

func end_round(success: bool) -> void:
	in_round = false
	round_ended.emit()
	
	if success:
		score += current_round * 100  # later tie to gold
	else:
		game_over.emit(current_round, score)
		save_high_score()
		return
	
	current_round += 1
	if current_round > DifficultySystem.total_rounds:
		game_over.emit(DifficultySystem.total_rounds, score)
		save_high_score()
	else:
		round_time = DifficultySystem.get_round_time(current_round)
		max_mana = DifficultySystem.get_max_mana(current_round)
		mana = minf(max_mana, mana)
		show_party_choice.emit()

func spend_mana(cost: float) -> bool:
	if mana >= cost:
		mana -= cost
		return true
	return false

func regen_mana(delta: float) -> void:
	mana = minf(max_mana, mana + regen_rate * delta)

func save_high_score() -> void:
	if score > high_score:
		high_score = score
		var config = ConfigFile.new()
		config.set_value("scores", "high", high_score)
		config.save("user://highscore.cfg")

func load_high_score() -> void:
	var config = ConfigFile.new()
	if config.load("user://highscore.cfg") == OK:
		high_score = config.get_value("scores", "high", 0)
