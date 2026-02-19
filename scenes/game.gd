extends Control

@onready var start_screen: Control       = $StartScreen
@onready var game_ui: Control            = $GameUI
@onready var round_label: Label          = $GameUI/Header/RoundLabel
@onready var timer_label: Label          = $GameUI/Header/TimerLabel
@onready var health_container: VBoxContainer = $GameUI/HealthContainer
@onready var cast_bar: ProgressBar       = $GameUI/CastBar
@onready var mana_bar: ProgressBar       = $GameUI/ManaBar
@onready var spell_container: HBoxContainer  = $GameUI/SpellContainer
@onready var party_panel: Control        = $GameUI/PartyChoicePanel
@onready var game_over_panel: Control    = $GameUI/GameOverPanel

@onready var score_label: Label          = $StartScreen/CenterContainer/HighScoreLabel
@onready var final_score_label: Label    = $GameUI/GameOverPanel/GameOverContainer/ScoreLabel   # ← fixed nesting
@onready var party_choice_panel: Control = $GameUI/PartyChoicePanel   # rename var if needed


var spell_buttons: Array[Button] = []

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.show_party_choice.connect(_show_party_choice)
	GameManager.round_started.connect(_on_new_round_started)
	TargetSystem.target_added.connect(_add_target)
	TargetSystem.loss_condition.connect(_on_loss)
	SpellSystem.cast_started.connect(_on_cast_start)
	SpellSystem.cast_finished.connect(_on_cast_finish)
	SpellSystem.selected_spell_changed.connect(_update_spell_ui)
	score_label.text = "High Score: %d" % GameManager.high_score
	party_panel.visible = false
	game_ui.visible = false
	cast_bar.visible = false
	start_screen.visible = true
	party_choice_panel.visible = false


func _process(delta: float) -> void:
	if not GameManager.in_round:
		return
	GameManager.round_time -= delta
	timer_label.text = "%.1fs" % GameManager.round_time
	GameManager.regen_mana(delta)
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100
	if GameManager.in_round:
		GameManager.round_time -= delta
		timer_label.text = "%.1fs" % GameManager.round_time
		if GameManager.round_time <= 0:
			GameManager.end_round(true)
	if SpellSystem.is_casting:
		cast_bar.value = (SpellSystem.cast_progress / SpellSystem.current_spell.cast_time) * 100
	if GameManager.round_time <= 0:
		GameManager.end_round(true)


	_update_spell_ui()
	_check_selected_target()

func _check_selected_target():
	# Optional: highlight selected target
	pass

func _add_target(target: Node) -> void:
	health_container.add_child(target)
	target.pressed.connect(func(t): _on_target_pressed(t))

func _show_party_choice() -> void:
	print("Showing party choice")
	party_choice_panel.visible = true
	party_choice_panel.setup(
		preload("res://resources/parties/iron_vanguard.tres"),
		preload("res://resources/parties/arcane_glass.tres")
	)

func _on_new_round_started(round: int) -> void:
	party_panel.visible = false
	round_label.text = "Round %d" % round
	health_container.visible = true

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
		btn.pressed.connect(func(): SpellSystem.selected_spell = spell)
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

func _on_target_pressed(target: Node) -> void:
	if selected_spell:
		SpellSystem.try_cast(selected_spell, target)
		selected_spell = null  # optional: deselect after cast
	else:
		print("No spell selected")


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
