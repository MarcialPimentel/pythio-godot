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

const TOTAL_ROUNDS = 5
const PARTY_PRESETS: Array[PartyPreset] = [
	preload("res://data/parties/arcane_glass.tres") as PartyPreset,
	preload("res://data/parties/iron_vanguard.tres") as PartyPreset,
]

func _ready() -> void:
	load_high_score()

func new_game() -> void:
	current_round = 1
	score = 0
	mana = 100.0
	max_mana = 100.0
	in_round = false
	round_time = 15.0
	show_party_choice.emit()

func start_round(choice: int) -> void:
	var preset = PARTY_PRESETS[choice % 2]  # Alternate or fixed
	TargetSystem.spawn_party(preset)
	in_round = true
	round_time = 15.0 + (current_round - 1) * 3.0
	max_mana = 100.0 + (current_round - 1) * 8.0
	mana = minf(max_mana, mana)
	round_started.emit(current_round)

func end_round(success: bool) -> void:
	in_round = false
	if success:
		score += current_round * 100
	if current_round < TOTAL_ROUNDS:
		current_round += 1
		round_ended.emit()
		show_party_choice.emit()
	else:
		game_over.emit(current_round, score)
		save_high_score()

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
