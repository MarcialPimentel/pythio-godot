class_name Game

extends Control

@onready var start_screen: Control       = $StartScreen
@onready var game_ui: Control            = $GameUI
@onready var round_label: Label          = $GameUI/Header/RoundLabel
@onready var timer_label: Label          = $GameUI/Header/TimerLabel

@onready var cast_bar: ProgressBar       = $GameUI/PlayerContainer/PlayerResources/CastBar
@onready var mana_bar: ProgressBar       = $GameUI/PlayerContainer/PlayerResources/ManaBar
@onready var spell_container: HBoxContainer  = $GameUI/SpellContainer

@onready var contract_selector = ContractSelector
@onready var party_choice_panel: Control = $GameUI/PartyChoicePanel
@onready var party_container: HBoxContainer = $GameUI/PartyContainer/PartyTarget

@onready var score_label: Label          = $StartScreen/CenterContainer/HighScoreLabel
@onready var final_score_label: Label    = $GameUI/GameOverPanel/GameOverContainer/ScoreLabel   # ← fixed nesting

@onready var game_over_panel: Control    = $GameUI/GameOverPanel
@onready var play_again_button: Button   = $GameUI/GameOverPanel/GameOverContainer/PlayAgainButton


var spell_buttons: Array[Button] = []
var mana_label: Label
var cast_label: Label

var current_contract: ContractData
var selected_target: Node = null   # optional, helps with future hover casting

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.show_party_choice.connect(_show_party_choice)
	GameManager.round_started.connect(_on_new_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	TargetSystem.target_added.connect(_add_target)
	TargetSystem.loss_condition.connect(_on_loss)
	SpellSystem.spell_cast_started.connect(_on_cast_start)
	SpellSystem.spell_cast_finished.connect(_on_cast_finish)
	SpellSystem.spell_cast_cancelled.connect(_on_cast_finish)
	SpellSystem.spell_cast_failed.connect(_on_cast_failed)
	mana_label = _add_bar_label(mana_bar)
	cast_label = _add_bar_label(cast_bar)
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
	EventBus.target_died.connect(func(t): fallen_name = t.display_name)
	play_again_button.pressed.connect(_on_play_again_pressed)
	
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
	_update_mana_bar()
	if SpellSystem.is_casting and SpellSystem.current_spell:
		cast_bar.value = SpellSystem.cast_progress() * 100.0
		var left := SpellSystem.current_spell.cast_time - SpellSystem.cast_elapsed
		cast_label.text = "Casting %s (%.1fs)" % [SpellSystem.current_spell.display_name, maxf(0.0, left)]
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
	
	var contracts = contract_selector.get_contracts_for_round(GameManager.current_round)
	print("Got ", contracts.size(), " contract(s) for round ", GameManager.current_round)
	
	party_choice_panel.setup_contracts(contracts)

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
	_update_mana_bar()
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
	# Keep the party on screen after a loss so you can see who fell
	await get_tree().process_frame
	if game_over_panel.visible:
		return
	party_container.visible = false
	# Next spawn will add new children after clear anyway

var fallen_name: String = ""

func _on_loss() -> void:
	if not GameManager.in_round:
		return   # already ended this round
	SpellSystem.cancel_cast()
	GameManager.end_round(false)

func _add_bar_label(bar: ProgressBar) -> Label:
	bar.show_percentage = false
	bar.custom_minimum_size.y = maxf(bar.custom_minimum_size.y, 20)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)
	return label

func _update_mana_bar() -> void:
	mana_bar.max_value = GameManager.max_mana
	mana_bar.value = GameManager.mana
	mana_label.text = "%d / %d" % [int(GameManager.mana), int(GameManager.max_mana)]

func _on_cast_start(spell: SpellData, _target) -> void:
	if spell.cast_time > 0.0:
		cast_bar.visible = true
		cast_bar.value = 0
		cast_label.text = "Casting %s" % spell.display_name

func _on_cast_finish(_spell: SpellData, _target) -> void:
	cast_bar.visible = false

func _on_cast_failed(spell: SpellData, reason: String) -> void:
	# Quick feedback until proper UI messages arrive (roadmap Phase 5)
	var msg := {"mana": "Not enough mana", "cooldown": "%s isn't ready" % spell.display_name,
		"busy": "Already casting", "no_target": "Hover or click a fighter first"}
	if msg.has(reason):
		print(msg[reason])
		if reason == "mana":
			var tw := create_tween()
			mana_bar.modulate = Color(1.0, 0.3, 0.3)
			tw.tween_property(mana_bar, "modulate", Color.WHITE, 0.4)

func _create_spell_buttons() -> void:
	for child in spell_container.get_children():
		child.queue_free()
	spell_buttons.clear()
	for i in SpellSystem.spells.size():
		var spell: SpellData = SpellSystem.spells[i]
		var key := SpellSystem.key_label_for_slot(i)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.icon = spell.icon
		btn.text = key
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.expand_icon = true
		btn.focus_mode = Control.FOCUS_NONE   # so Q/W/E/R aren't swallowed by button focus
		var cast_txt := "Instant" if spell.cast_time <= 0.0 else "%.1fs cast" % spell.cast_time
		btn.tooltip_text = "%s [%s]\nMana: %d · %s%s" % [spell.display_name, key, spell.mana_cost, cast_txt,
			("" if spell.cooldown <= 0.0 else " · %.0fs cooldown" % spell.cooldown)]
		btn.pressed.connect(func(): _on_spell_pressed(spell))
		spell_container.add_child(btn)
		spell_buttons.append(btn)

func _update_spell_ui() -> void:
	for i in spell_buttons.size():
		var spell = SpellSystem.spells[i]
		var btn = spell_buttons[i]
		btn.disabled = not SpellSystem.can_cast(spell)
		var key := SpellSystem.key_label_for_slot(i)
		var cd := SpellSystem.cooldown_remaining(spell.id)
		btn.text = key if cd <= 0.0 else "%s %.0f" % [key, ceilf(cd)]
		if selected_spell == spell:
			btn.modulate = Color.YELLOW
		else:
			btn.modulate = Color.WHITE


var selected_spell: SpellData = null

func _on_spell_pressed(spell: SpellData) -> void:
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
	mana_bar.visible = true
	_create_spell_buttons()
	GameManager.new_game()

func _on_game_over(round_reached: int, final_score: int) -> void:
	party_choice_panel.visible = false
	game_over_panel.visible = true
	if GameManager.last_run_won:
		final_score_label.text = "Contract fulfilled. All %d rounds survived.\nScore: %d" % [round_reached, final_score]
	else:
		final_score_label.text = "%s didn't make it.\nRun ended in round %d.  Score: %d" % [fallen_name if fallen_name != "" else "Someone", round_reached, final_score]
	score_label.text = "High Score: %d" % GameManager.high_score

func _on_play_again_pressed() -> void:
	game_over_panel.visible = false
	fallen_name = ""
	round_label.modulate = Color.WHITE
	_clear_party_container()
	GameManager.new_game()

# Call _create_spell_buttons() in _ready if buttons not pre-made


func _on_start_button_pressed() -> void:
	pass # Replace with function body.
