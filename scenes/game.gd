class_name Game

extends Control

@onready var start_screen: Control       = $StartScreen
@onready var game_ui: Control            = $GameUI
@onready var round_label: Label          = $GameUI/Header/RoundLabel
@onready var timer_label: Label          = $GameUI/Header/TimerLabel

@onready var cast_bar: ProgressBar       = $GameUI/PlayerContainer/PlayerResources/CastBar
@onready var mana_bar: ProgressBar       = $GameUI/PlayerContainer/PlayerResources/ManaBar
@onready var spell_container: HBoxContainer  = $GameUI/SpellContainer

@onready var party_choice_panel: Control = $GameUI/PartyChoicePanel
@onready var party_container: HBoxContainer = $GameUI/PartyContainer/PartyTarget

@onready var score_label: Label          = $StartScreen/CenterContainer/HighScoreLabel
@onready var final_score_label: Label    = $GameUI/GameOverPanel/GameOverContainer/ScoreLabel   # ← fixed nesting

@onready var game_over_panel: Control    = $GameUI/GameOverPanel


var spell_buttons: Array[Button] = []

var current_contract: ContractData
var selected_target: Node = null   # optional, helps with future hover casting

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.show_party_choice.connect(_show_party_choice)
	GameManager.round_started.connect(_on_new_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	TargetSystem.target_added.connect(_add_target)
	TargetSystem.loss_condition.connect(_on_loss)
	SpellSystem.cast_started.connect(_on_cast_start)
	SpellSystem.cast_finished.connect(_on_cast_finish)
	SpellSystem.selected_spell_changed.connect(_update_spell_ui)
	score_label.text = "High Score: %d" % GameManager.high_score
	party_choice_panel.visible = false
	game_ui.visible = false
	cast_bar.visible = false
	start_screen.visible = true
	party_choice_panel.visible = false
	party_choice_panel.contract_chosen.connect(_on_contract_chosen)
	TargetSystem.all_targets_dead.connect(_on_loss)
	EventBus.target_selected.connect(_on_target_selected)
	
	# Safe connect pattern
	if not party_choice_panel.contract_chosen.is_connected(_on_contract_chosen):
		party_choice_panel.contract_chosen.connect(_on_contract_chosen)
	
	if not EventBus.target_selected.is_connected(_on_target_selected):
		EventBus.target_selected.connect(_on_target_selected)

func _process(delta: float) -> void:
	if not GameManager.in_round:
		return
	
	GameManager.round_time -= delta
	if GameManager.round_time <= 0:
		GameManager.round_time = 0
		GameManager.end_round(true)
		return
	
	timer_label.text = "%.1fs" % GameManager.round_time
	GameManager.regen_mana(delta)
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100
	if SpellSystem.is_casting:
		cast_bar.value = (SpellSystem.cast_progress / SpellSystem.current_spell.cast_time) * 100
	
	_update_spell_ui()
	_check_selected_target()

func _check_selected_target():
	# Optional: highlight selected target
	pass

func _add_target(target: Node) -> void:
	party_container.add_child(target)

func _remove_target(target: Node) -> void:
	party_container.remove_child(target)

func _show_party_choice() -> void:
	print("Showing party choice - procedural contracts")
	party_choice_panel.visible = true
	
	# NEW: generate 2 choices (or 1 for boss round)
	var current_round = GameManager.current_round   # assuming GameManager tracks this
	var choices: Array = ContractGenerator.generate_two_choices(current_round)
	
	# Pass to panel (we'll update PartyChoicePanel.gd next to handle ContractData)
	party_choice_panel.setup_contracts(choices)

func _on_contract_chosen(chosen: ContractData) -> void:
	# Guard against duplicate calls (common during signal spam or double-clicks)
	if not party_choice_panel.visible:
		print_debug("Ignoring duplicate contract chosen call")
		return
	
	current_contract = chosen
	party_choice_panel.visible = false
	
	# 1. Clean up previous round visuals and state
	_clear_party_container()
	TargetSystem.clear_targets()  # also clears internal array
	
	# 2. Spawn new party (delegated to TargetSystem for modularity)
	TargetSystem.spawn_from_contract(chosen)
	
	# 3. Start round via centralized event
	GameManager.in_round = true
	EventBus.round_started.emit(GameManager.current_round)
	
	print("Round started with contract: %s - units: %d" % [
		chosen.contract_name, 
		chosen.unit_templates.size()
	])

func _clear_party_container() -> void:
	for child in party_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	# Also clear TargetSystem's internal list to prevent stale references
	TargetSystem.clear_targets()

func _on_new_round_started(round: int) -> void:
	party_choice_panel.visible = false
	round_label.text = "Round %d" % round

func _on_round_ended() -> void:
	party_container.visible = false
	TargetSystem.clear_targets()  # foundational cleanup

func _on_loss() -> void:
	GameManager.end_round(false)

func _on_cast_start() -> void:
	cast_bar.visible = true
	cast_bar.value = 0

func _on_cast_finish(_spell: Spell) -> void:
	cast_bar.visible = false

func _create_spell_buttons() -> void:
	for child in spell_container.get_children():
		child.queue_free()
	spell_buttons.clear()
	for spell in SpellSystem.spells:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.icon = spell.icon
		btn.tooltip_text = "%s\nMana: %d" % [spell.display_name, spell.mana_cost]
		#btn.pressed.connect(func(): SpellSystem.selected_spell = spell)
		btn.pressed.connect(func(): _on_spell_pressed(spell))
		spell_container.add_child(btn)
		spell_buttons.append(btn)

func _update_spell_ui() -> void:
	for i in spell_buttons.size():
		var spell = SpellSystem.spells[i]
		var btn = spell_buttons[i]
		var can_cast = not SpellSystem.is_casting and GameManager.mana >= spell.mana_cost
		btn.disabled = not can_cast
		if SpellSystem.selected_spell == spell:
			btn.modulate = Color.YELLOW
		else:
			btn.modulate = Color.WHITE


var selected_spell: Spell = null

func _on_spell_pressed(spell: Spell) -> void:
	selected_spell = spell
	print("Selected spell:", spell.display_name)

func _on_target_selected(target: Node) -> void:
	if not selected_spell:
		print("No spell selected")
		return
	
	# Optional early checks (mana, casting state) – but prefer SpellSystem owns them
	EventBus.spell_cast_requested.emit(selected_spell, target)
	selected_spell = null  # deselect after request

func _on_start_pressed() -> void:
	start_screen.visible = false
	game_ui.visible = true
	_create_spell_buttons()
	GameManager.new_game()

func _on_game_over(round_reached: int, final_score: int) -> void:
	game_over_panel.visible = true
	final_score_label.text = "Round %d Complete!\nScore: %d" % [round_reached, final_score]
	var play_again_btn = game_over_panel.get_node("PlayAgainButton")
	if play_again_btn:
		play_again_btn.pressed.connect(func(): GameManager.new_game(); game_over_panel.visible = false)

# Call _create_spell_buttons() in _ready if buttons not pre-made


func _on_start_button_pressed() -> void:
	pass # Replace with function body.
