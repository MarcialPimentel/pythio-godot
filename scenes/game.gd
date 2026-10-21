class_name Game

extends Control

# ── Scene references ──
@onready var start_screen: Control       = $StartScreen
@onready var game_ui: Control            = $GameUI
@onready var round_label: Label          = $GameUI/Header/RoundLabel
@onready var timer_label: Label          = $GameUI/Header/TimerLabel

@onready var contract_name_label: Label  = $GameUI/ContractInfo/ContractName
@onready var contract_risk_label: Label  = $GameUI/ContractInfo/ContractRisk
@onready var contract_info: Control      = $GameUI/ContractInfo

@onready var cast_bar: ProgressBar       = $GameUI/PlayerContainer/PlayerResources/CastBar
@onready var mana_bar: TextureProgressBar = $GameUI/PlayerContainer/PlayerResources/ManaBar
@onready var mana_orb: TextureRect       = $GameUI/PlayerContainer/PlayerResources/ManaOrb
@onready var spell_container: HBoxContainer  = $GameUI/SpellContainer

@onready var pythio_sprite: TextureRect  = $GameUI/Pythio
@onready var quip_bubble: TextureRect    = $GameUI/QuipBubble
@onready var quip_label: Label           = $GameUI/QuipBubble/QuipLabel

@onready var contract_selector = ContractSelector
@onready var party_choice_panel: Control = $GameUI/PartyChoicePanel
@onready var party_area: Control         = $GameUI/PartyContainer
@onready var party_container: HBoxContainer = $GameUI/PartyContainer/PartyTarget

@onready var score_label: Label          = $StartScreen/CenterContainer/HighScoreLabel
@onready var final_score_label: Label    = $GameUI/GameOverPanel/GameOverContainer/ScoreLabel
@onready var game_over_panel: Control    = $GameUI/GameOverPanel
@onready var play_again_button: Button   = $GameUI/GameOverPanel/GameOverContainer/PlayAgainButton
@onready var name_edit: LineEdit         = $GameUI/GameOverPanel/GameOverContainer/SubmitRow/NameEdit
@onready var submit_button: Button       = $GameUI/GameOverPanel/GameOverContainer/SubmitRow/SubmitButton
@onready var submit_status: Label        = $GameUI/GameOverPanel/GameOverContainer/SubmitStatus
@onready var lb_grid: GridContainer      = $StartScreen/LeaderboardPanel/LeaderboardBox/LeaderboardGrid
@onready var lb_status: Label            = $StartScreen/LeaderboardPanel/LeaderboardBox/LeaderboardStatus

const ART := "res://assets/art/"
## Spellbook size: keys Q W E R T. Empty slots show as "draft" until spell drafting exists.
const SPELL_SLOTS := 5
## Spell icon by spell id (falls back to the icon set on the SpellData resource).
const SPELL_ICONS := {
	"flash_heal": "ui/icons/spell_flash_heal.png",
	"renew": "ui/icons/spell_hot.png",
	"shield": "ui/icons/spell_shield.png",
	"heal": "ui/icons/spell_instant_heal.png",
}
## Pythio's pose while casting each kind of effect.
const CAST_POSES := {"instant_heal": "cast_heal", "hot": "cast_hot", "shield": "cast_shield"}

## Pythio's dry one-liners. Edit freely.
const QUIPS := {
	"round_start": ["Hold still. This stings less than dying.", "Everyone breathing? Keep it that way.",
		"I charge by the hour. Try not to bleed by the minute.", "Another job. Same blood."],
	"boss": ["The Baron. Of course it's the Baron.", "Big man, big wounds, big invoice."],
	"low_mana": ["Running on fumes.", "Pace yourselves. I'm not a fountain."],
	"death": ["Well. That's a refund I won't be getting.", "Should've ducked."],
	"victory": ["Contract fulfilled. Nobody died. Mostly.", "Pay up. I take coin, not thanks."],
}

var spell_buttons: Array[Button] = []
var mana_label: Label
var cast_label: Label
var selected_spell: SpellData = null
var current_contract: ContractData
var fallen_name: String = ""
var _pose_reset_at := 0.0
var _low_mana_warned := false
var _quip_tween: Tween
var _last_run := {"score": 0, "round": 1, "won": false}


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.show_party_choice.connect(_show_party_choice)
	TargetSystem.loss_condition.connect(_on_loss)
	SpellSystem.spell_cast_started.connect(_on_cast_start)
	SpellSystem.spell_cast_finished.connect(_on_cast_finish)
	SpellSystem.spell_cast_cancelled.connect(_on_cast_finish)
	SpellSystem.spell_cast_failed.connect(_on_cast_failed)
	party_choice_panel.contract_chosen.connect(_on_contract_chosen)
	EventBus.target_selected.connect(_on_target_selected)
	EventBus.targets_spawned.connect(_on_targets_spawned)
	EventBus.round_ended.connect(_on_round_ended)
	EventBus.target_died.connect(_on_target_died)
	play_again_button.pressed.connect(_on_play_again_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	name_edit.text_submitted.connect(func(_t): _on_submit_pressed())
	Leaderboard.top_loaded.connect(_show_leaderboard)
	Leaderboard.submitted.connect(_on_score_submitted)
	Leaderboard.fetch_top()

	cast_label = _add_bar_label(cast_bar, 18)
	mana_label = _add_bar_label(mana_bar, 20)
	mana_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mana_label.position = Vector2(16, 12)
	mana_label.size = Vector2(336, 27)

	quip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quip_label.size = Vector2(quip_bubble.size.x - 84, quip_bubble.size.y - 60)

	score_label.text = "High Score: %d" % GameManager.high_score
	game_ui.visible = false
	cast_bar.visible = false
	party_choice_panel.visible = false
	start_screen.visible = true


func _process(delta: float) -> void:
	if _pose_reset_at > 0.0 and Time.get_ticks_msec() / 1000.0 > _pose_reset_at and not SpellSystem.is_casting:
		_pose_reset_at = 0.0
		_set_pose("idle")

	if not GameManager.in_round:
		return

	timer_label.text = "%.1fs" % GameManager.round_time
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
		cast_label.text = "Casting %s  %.1fs" % [SpellSystem.current_spell.display_name, maxf(0.0, left)]
	_update_spell_ui()


# ── Rounds & contracts ─────────────────────────────────

func _show_party_choice() -> void:
	party_choice_panel.visible = true
	party_area.visible = false
	contract_info.visible = false
	var contracts = contract_selector.get_contracts_for_round(GameManager.current_round)
	party_choice_panel.setup_contracts(contracts)
	round_label.text = "Round %d" % GameManager.current_round
	timer_label.text = "Choose your contract"


func _on_contract_chosen(chosen: ContractData) -> void:
	current_contract = chosen
	party_choice_panel.visible = false
	await _clear_party_container()

	contract_name_label.text = chosen.contract_name.replace("  ", " ")
	contract_risk_label.text = "RISK %d / 5" % chosen.risk_level
	contract_info.visible = true
	round_label.text = "The Final Contract" if chosen.is_boss else "Round %d" % GameManager.current_round
	round_label.modulate = Color(1, 0.35, 0.3) if chosen.is_boss else Color.WHITE

	TargetSystem.spawn_from_contract(chosen)
	GameManager.in_round = true
	_low_mana_warned = false
	EventBus.round_started.emit(GameManager.current_round)
	_update_mana_bar()
	party_area.visible = true
	_say("boss" if chosen.is_boss else "round_start")


func _on_targets_spawned(new_targets: Array[Node]) -> void:
	for target in new_targets:
		if not is_instance_valid(target):
			continue
		if target.get_parent() != null:
			target.get_parent().remove_child(target)
		party_container.add_child(target)
	_fit_party(new_targets.size())


func _fit_party(count: int) -> void:
	# Shrink the party row when a big contract wouldn't fit across the screen.
	var frame_w := 300.0
	var sep := float(party_container.get_theme_constant("separation"))
	var needed := count * frame_w + maxi(0, count - 1) * sep
	var avail := 1800.0
	var s := minf(1.0, avail / maxf(needed, 1.0))
	party_area.size.x = maxf(avail, needed)
	party_area.scale = Vector2(s, s)
	party_area.position.x = (1920.0 - party_area.size.x * s) / 2.0
	party_area.position.y = 230.0 + (1.0 - s) * 300.0


func _clear_party_container() -> void:
	TargetSystem.clear_targets()
	for child in party_container.get_children():
		child.queue_free()
	await get_tree().process_frame


func _on_round_ended(_round_num: int) -> void:
	cast_bar.visible = false
	# Keep the party on screen after a loss so you can see who fell
	await get_tree().process_frame
	if game_over_panel.visible:
		return
	party_area.visible = false


func _on_target_died(t: Node) -> void:
	fallen_name = t.display_name
	_set_pose("hurt", 99.0)
	_say("death")


func _on_loss() -> void:
	if not GameManager.in_round:
		return   # already ended this round
	SpellSystem.cancel_cast()
	GameManager.end_round(false)


# ── Mana, casting, spell bar ───────────────────────────

func _add_bar_label(bar: Control, font_size: int) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	bar.add_child(label)
	return label


func _update_mana_bar() -> void:
	mana_bar.max_value = GameManager.max_mana
	mana_bar.value = GameManager.mana
	mana_label.text = "%d / %d" % [int(GameManager.mana), int(GameManager.max_mana)]
	var frac := GameManager.mana / maxf(1.0, GameManager.max_mana)
	var orb := clampi(int(ceil(frac * 4.0)), 1, 4)
	var tex = load(ART + "ui/bars/mana_orb_%d.png" % orb)
	if tex and mana_orb.texture != tex:
		mana_orb.texture = tex
	if GameManager.in_round and frac < 0.2 and not _low_mana_warned:
		_low_mana_warned = true
		_set_pose("low_mana", 2.0)
		_say("low_mana")


func _on_cast_start(spell: SpellData, _target) -> void:
	_set_pose(CAST_POSES.get(spell.effect_type, "cast_heal"), maxf(0.5, spell.cast_time + 0.3))
	if spell.cast_time > 0.0:
		cast_bar.visible = true
		cast_bar.value = 0
		cast_label.text = "Casting %s" % spell.display_name


func _on_cast_finish(_spell: SpellData, _target) -> void:
	cast_bar.visible = false


func _on_cast_failed(spell: SpellData, reason: String) -> void:
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
	for i in SPELL_SLOTS:
		var key := SpellSystem.key_label_for_slot(i)
		if i < SpellSystem.spells.size():
			var spell: SpellData = SpellSystem.spells[i]
			var btn := _make_spell_slot(spell, key)
			btn.pressed.connect(func(): _on_spell_pressed(spell))
			spell_container.add_child(btn)
			spell_buttons.append(btn)
		else:
			spell_container.add_child(_make_empty_slot(key))


func _make_spell_slot(spell: SpellData, key: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(104, 116)
	btn.focus_mode = Control.FOCUS_NONE   # so Q/W/E/R aren't swallowed by button focus
	btn.flat = true
	var cast_txt := "Instant" if spell.cast_time <= 0.0 else "%.1fs cast" % spell.cast_time
	btn.tooltip_text = "%s  [%s]\nMana %d · %s%s" % [spell.display_name, key, spell.mana_cost, cast_txt,
		("" if spell.cooldown <= 0.0 else " · %.0fs cooldown" % spell.cooldown)]

	var icon := TextureRect.new()
	icon.name = "Icon"
	var icon_path: String = ART + SPELL_ICONS.get(spell.id, "")
	icon.texture = load(icon_path) if SPELL_ICONS.has(spell.id) and ResourceLoader.exists(icon_path) else spell.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	var cd := ColorRect.new()
	cd.name = "Cooldown"
	cd.color = Color(0, 0, 0, 0.65)
	cd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.visible = false
	btn.add_child(cd)

	btn.add_child(_slot_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	btn.add_child(_slot_label("Cost", str(int(spell.mana_cost)), 20, Color(1.0, 0.8, 0.35), Vector2(-6, 82), HORIZONTAL_ALIGNMENT_RIGHT))
	var cd_label := _slot_label("CdText", "", 34, Color.WHITE, Vector2(0, 36), HORIZONTAL_ALIGNMENT_CENTER)
	btn.add_child(cd_label)
	return btn


func _make_empty_slot(key: String) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(104, 116)
	p.modulate = Color(1, 1, 1, 0.45)
	p.tooltip_text = "Empty — you'll draft spells into this slot between rounds."
	p.add_child(_slot_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	p.add_child(_slot_label("Draft", "draft", 18, Color(0.6, 0.58, 0.55), Vector2(0, 44), HORIZONTAL_ALIGNMENT_CENTER))
	return p


func _slot_label(n: String, text: String, size: int, color: Color, offset: Vector2, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.name = n
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.position = offset
	l.size = Vector2(104, 34)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _update_spell_ui() -> void:
	for i in spell_buttons.size():
		var spell: SpellData = SpellSystem.spells[i]
		var btn := spell_buttons[i]
		var castable := SpellSystem.can_cast(spell)
		btn.disabled = not castable
		var cd := SpellSystem.cooldown_remaining(spell.id)
		btn.get_node("Cooldown").visible = cd > 0.0
		btn.get_node("CdText").text = "%d" % ceili(cd) if cd > 0.0 else ""
		var col := Color.WHITE
		if selected_spell == spell:
			col = Color(1.25, 1.15, 0.7)
		elif not castable:
			col = Color(0.5, 0.5, 0.5)
		btn.modulate = col
		btn.scale = Vector2.ONE * (1.06 if selected_spell == spell else 1.0)
		btn.pivot_offset = btn.size / 2.0


func _on_spell_pressed(spell: SpellData) -> void:
	selected_spell = spell


func _on_target_selected(target: Node) -> void:
	if selected_spell:
		EventBus.spell_cast_requested.emit(selected_spell, target)


# ── Pythio: poses and quips ────────────────────────────

func _set_pose(pose: String, hold: float = 0.0) -> void:
	var tex = load(ART + "characters/pythio/pythio_%s.png" % pose) if ResourceLoader.exists(ART + "characters/pythio/pythio_%s.png" % pose) else null
	if tex:
		pythio_sprite.texture = tex
	_pose_reset_at = (Time.get_ticks_msec() / 1000.0 + hold) if hold > 0.0 else 0.0


func _say(kind: String, seconds: float = 3.5) -> void:
	var lines: Array = QUIPS.get(kind, [])
	if lines.is_empty():
		return
	quip_label.text = lines[randi() % lines.size()]
	quip_bubble.visible = true
	quip_bubble.modulate.a = 1.0
	if _quip_tween:
		_quip_tween.kill()
	_quip_tween = create_tween()
	_quip_tween.tween_interval(seconds)
	_quip_tween.tween_property(quip_bubble, "modulate:a", 0.0, 0.5)
	_quip_tween.tween_callback(func(): quip_bubble.visible = false)


# ── Start / game over ──────────────────────────────────

func _on_start_pressed() -> void:
	start_screen.visible = false
	game_ui.visible = true
	_set_pose("idle")
	_create_spell_buttons()
	GameManager.new_game()


func _on_game_over(round_reached: int, final_score: int) -> void:
	party_choice_panel.visible = false
	game_over_panel.visible = true
	cast_bar.visible = false
	if GameManager.last_run_won:
		final_score_label.text = "Contract fulfilled.\nAll %d rounds survived.  Score: %d" % [round_reached, final_score]
		_set_pose("victory", 99.0)
		_say("victory", 6.0)
	else:
		final_score_label.text = "%s didn't make it.\nRun ended in round %d.  Score: %d" % [fallen_name if fallen_name != "" else "Someone", round_reached, final_score]
	score_label.text = "High Score: %d" % GameManager.high_score
	# Leaderboard entry
	_last_run = {"score": final_score, "round": maxi(1, round_reached), "won": GameManager.last_run_won}
	name_edit.text = Leaderboard.load_player_name()
	submit_button.disabled = false
	name_edit.editable = true
	submit_status.text = "Post your run to the marz.gg leaderboard."


func _on_submit_pressed() -> void:
	var player := name_edit.text.strip_edges()
	if player == "":
		submit_status.text = "Enter a name first."
		name_edit.grab_focus()
		return
	submit_button.disabled = true
	name_edit.editable = false
	submit_status.text = "Posting…"
	Leaderboard.submit(player, _last_run.score, _last_run.round, _last_run.won)


func _on_score_submitted(ok: bool, rank: int, entries: Array, message: String) -> void:
	if ok:
		submit_status.text = "Posted. You're #%d on the board." % rank
		_show_leaderboard(true, entries)
	else:
		submit_status.text = message
		submit_button.disabled = false
		name_edit.editable = true


func _show_leaderboard(ok: bool, entries: Array) -> void:
	for c in lb_grid.get_children():
		c.queue_free()
	if not ok:
		lb_status.text = "Leaderboard offline. It works once the game is on marz.gg."
		return
	lb_status.text = "No one yet. Be the first." if entries.is_empty() else ""
	for i in entries.size():
		var e: Dictionary = entries[i]
		var gold := Color(0.95, 0.78, 0.35) if i == 0 else Color(0.9, 0.87, 0.8)
		_lb_cell("%d." % (i + 1), gold)
		_lb_cell(str(e.get("name", "?")), gold, true)
		_lb_cell(str(int(e.get("score", 0))), gold)
		_lb_cell("WON" if e.get("won", false) else "R%d" % int(e.get("round", 0)),
			Color(0.45, 0.9, 0.4) if e.get("won", false) else Color(0.6, 0.58, 0.55))


func _lb_cell(text: String, color: Color, expand := false) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 24)
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
	lb_grid.add_child(l)


func _on_play_again_pressed() -> void:
	game_over_panel.visible = false
	fallen_name = ""
	round_label.modulate = Color.WHITE
	_set_pose("idle")
	await _clear_party_container()
	GameManager.new_game()
