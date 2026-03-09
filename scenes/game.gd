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
	mana_bar.visible = false
	party_choice_panel.contract_chosen.connect(_on_contract_chosen)
	TargetSystem.all_targets_dead.connect(_on_loss)
	EventBus.target_selected.connect(_on_target_selected)
	EventBus.targets_spawned.connect(_on_targets_spawned)
	EventBus.round_ended.connect(_on_round_ended)
	
	# Safe connect pattern
	if not party_choice_panel.contract_chosen.is_connected(_on_contract_chosen):
		party_choice_panel.contract_chosen.connect(_on_contract_chosen)
	
	if not EventBus.target_selected.is_connected(_on_target_selected):
		EventBus.target_selected.connect(_on_target_selected)

func _process(delta: float) -> void:
	if not GameManager.in_round:
		return
	
	timer_label.visible = true
	timer_label.text = "%.1fs" % GameManager.round_time
	round_label.visible = true
	round_label.text = "Round %d" % GameManager.current_round
	
	GameManager.round_time -= delta
	if GameManager.round_time <= 0:
		GameManager.round_time = 0
		GameManager.end_round(true)
		return	
	
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
	print("=== _show_party_choice ===")
	print("Round:", GameManager.current_round)
	
	party_choice_panel.visible = true
	
	if GameManager.current_round == 5:
		# Final round: single harder contract, no real choice
		var boss_contract = ContractGenerator.generate_boss_contract(GameManager.current_round)
		print("Final contract generated:", boss_contract.contract_name)
		
		# Feed only one contract to the panel
		var single: Array[ContractData] = [boss_contract]
		party_choice_panel.setup_contracts(single)
		
		# Visually disable right side
		party_choice_panel.right_button.disabled = true
		party_choice_panel.right_name.text = "Locked"
		party_choice_panel.right_gold.text = "—"
		if party_choice_panel.right_flavor:
			party_choice_panel.right_flavor.text = "Only the final job remains…"
	else:
		# Normal rounds: two choices
		var choices = ContractGenerator.generate_two_choices(GameManager.current_round)
		print("Normal choices generated:", choices.size())
		party_choice_panel.setup_contracts(choices)

func _on_targets_spawned(new_targets: Array[Node]) -> void:
	print("Spawning ", new_targets.size(), " new targets")
	
	for target in new_targets:
		if not is_instance_valid(target):
			continue
		
		var parent = target.get_parent()
		if parent != null:
			if parent == party_container:
				print("Target already parented — removing first")
				parent.remove_child(target)
			else:
				print("Wrong parent ", parent.name, " — reparenting")
				parent.remove_child(target)
		
		party_container.add_child(target)
		print("Added ", target.name if "name" in target else "Target", " (index ", target.index if "index" in target else "?", ")")
	
	party_container.queue_sort()
	party_container.update_minimum_size()
	print("Container now has ", party_container.get_child_count(), " children")

func _on_contract_chosen(chosen: ContractData) -> void:
	print("=== Contract chosen ===")
	print("Name:", chosen.contract_name, " | Boss:", chosen.is_boss, " | Units:", chosen.unit_templates.size())
	
	current_contract = chosen
	
	# Hide panel regardless (safe even if already hidden)
	party_choice_panel.visible = false
	print("Choice panel hidden")
	
	# REMOVE or COMMENT this guard — it's causing early return in boss case
	# if not party_choice_panel.visible:
	#     return
	
	# Proceed with cleanup and spawn EVERY time
	_clear_party_container()
	print("Cleanup called")
	
	TargetSystem.spawn_from_contract(chosen)
	print("Spawn called")
	
	GameManager.in_round = true
	EventBus.round_started.emit(GameManager.current_round)
	print("Round started emitted - in_round now true")
	
	# Ensure container is visible
	party_container.visible = true
	print("Forced party_container.visible = true")

func _clear_party_container() -> void:
	print("CLEARING party_container — children before: ", party_container.get_child_count())
	
	# Phase 1: Clean old targets via system (this queues free on anything it knows)
	TargetSystem.clear_targets()
	
	# Phase 2: Immediately free anything still in the container (old stragglers)
	# Do this BEFORE awaiting — so new adds happen after
	var children_to_free = party_container.get_children().duplicate()  # snapshot
	for child in children_to_free:
		if is_instance_valid(child):
			print("Immediate free on pre-spawn child: ", child.name if "name" in child else child)
			child.queue_free()
	
	# Now wait for frees to process
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Phase 3: Final check — should be 0 now, but no more freeing here
	print("party_container after cleanup & await — children now: ", party_container.get_child_count())
	
	# Force layout refresh
	party_container.queue_redraw()
	party_container.update_minimum_size()
	
func _on_new_round_started(round: int) -> void:
	party_choice_panel.visible = false
	round_label.text = "Round %d" % round
	if round == 5:
		round_label.modulate = Color(1, 0.2, 0.2)  # Red for final round
		# Optional: play sound, show "FINAL CONTRACT" overlay

func _on_round_ended(round_num: int) -> void:
	print("Round ended — hiding party")
	party_container.visible = false
	# Next spawn will add new children after clear anyway

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
	
	print("Requesting cast: ", selected_spell.display_name, " on target ", target.index if "index" in target else "?")
	EventBus.spell_cast_requested.emit(selected_spell, target)

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
