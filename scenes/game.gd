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
## Spellbook size: keys Q W E R T. Empty slots wait for a spell pick.
const SPELL_SLOTS := 5
## Spell icon by spell id; other spells use the icon for their main tag (stand-in art).
const SPELL_ICONS := {
	"flash_heal": "ui/icons/spell_flash_heal.png",
	"renew": "ui/icons/spell_hot.png",
	"shield": "ui/icons/spell_shield.png",
	"heal": "ui/icons/spell_instant_heal.png",
}
const TAG_ICONS := {
	"SHIELD": "ui/icons/spell_shield.png",
	"HOT": "ui/icons/spell_hot.png",
	"DIRECT": "ui/icons/spell_instant_heal.png",
	"DELAYED": "ui/icons/status_buff_2.png",
}
const FALLBACK_ICON := "ui/icons/status_buff_4.png"

## Pythio's dry one-liners. Edit freely.
const QUIPS := {
	"round_start": ["Hold still. This stings less than dying.", "Everyone breathing? Keep it that way.",
		"I charge by the hour. Try not to bleed by the minute.", "Another job. Same blood."],
	"boss": ["The Baron. Of course it's the Baron.", "Big man, big wounds, big invoice."],
	"low_mana": ["Running on fumes.", "Pace yourselves. I'm not a fountain."],
	"death": ["Well. That's a refund I won't be getting.", "Should've ducked."],
	"victory": ["Contract fulfilled. Nobody died. Mostly.", "Pay up. I take coin, not thanks."],
	"spec": ["Every healer has a habit. Pick yours.", "Choose how you'll keep them breathing."],
	"pick": ["New trick. Try not to waste it.", "The job pays in spells. Pick one."],
	"build_complete": ["That's the whole kit. Now let's see how far it goes.", "No more tricks. Just you and the bleeding."],
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
var card_panel: Control
## What the open card screen is choosing: "spec" or "spell", and the options shown.
var _card_mode := ""
var _card_options: Array = []


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.show_party_choice.connect(_show_party_choice)
	GameManager.show_spec_choice.connect(_show_spec_choice)
	GameManager.show_spell_pick.connect(_show_spell_pick)
	DraftSystem.build_complete.connect(func(): _say("build_complete", 5.0))
	TargetSystem.loss_condition.connect(_on_loss)
	SpellSystem.spell_cast_started.connect(_on_cast_start)
	SpellSystem.spell_cast_finished.connect(_on_cast_finish)
	SpellSystem.spell_cast_cancelled.connect(_on_cast_finish)
	SpellSystem.spell_cast_failed.connect(_on_cast_failed)
	SpellSystem.spellbook_changed.connect(func(): if game_ui.visible: _create_spell_buttons())
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

	_add_build_label()
	card_panel = preload("res://ui/CardChoicePanel.gd").new()
	game_ui.add_child(card_panel)
	card_panel.chosen.connect(_on_card_chosen)
	add_child(preload("res://ui/DebugPanel.gd").new())

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


# ── Specialization and spell picks ─────────────────────

func _show_spec_choice() -> void:
	party_choice_panel.visible = false
	party_area.visible = false
	contract_info.visible = false
	round_label.text = "A new job"
	timer_label.text = "Choose your school"
	_card_mode = "spec"
	_card_options = DraftSystem.specs.duplicate()
	var cards: Array = []
	for spec in _card_options:
		cards.append(spec_card(spec))
	card_panel.show_cards("Choose your school", "It decides your first spell and which spells you're offered most.", cards)
	_say("spec", 5.0)


func _show_spell_pick(offers: Array, round_cleared: int) -> void:
	party_choice_panel.visible = false
	party_area.visible = false
	contract_info.visible = false
	round_label.text = "Round %d cleared" % round_cleared
	timer_label.text = "Pick a spell"
	_card_mode = "spell"
	_card_options = offers.duplicate()
	var cards: Array = []
	for spell in _card_options:
		cards.append(spell_card(spell))
	var used := SpellSystem.spells.size()
	var sub := "Spellbook %d / %d" % [used, DraftSystem.spellbook_cap]
	sub += " — full: only rank-ups from here." if DraftSystem.is_full() else " — next pick after round %d." % _next_pick_round(round_cleared)
	card_panel.show_cards("Add a spell", sub, cards)
	_say("pick", 4.0)


func _next_pick_round(after: int) -> int:
	var r := after + 1
	while not DraftSystem.is_pick_round(r) and r < after + 1000:
		r += 1
	return r


func _on_card_chosen(index: int) -> void:
	var choice = _card_options[index]
	match _card_mode:
		"spec":
			DraftSystem.choose_spec(choice)
		"spell":
			DraftSystem.take(choice)
	_card_mode = ""
	GameManager.continue_to_contracts()


## Card data for a school on the specialization screen.
func spec_card(spec: SpecData) -> Dictionary:
	var color: Color = SpellTags.SCHOOL_COLORS.get(spec.school, Color.WHITE)
	var starter := spec.starter
	var body := "[color=#%s]%s[/color]\n\n" % [Color(0.85, 0.82, 0.76).to_html(false), spec.description]
	if starter:
		body += "[b]Starts with %s[/b] — %s\n[color=#%s]%s[/color]" % [starter.display_name, starter.description_bb(),
			Color(1.0, 0.8, 0.35).to_html(false), starter.stats_line()]
	return {
		"header": "SCHOOL", "header_color": color, "accent": color,
		"icon": spell_icon(starter) if starter else null,
		"title": spec.display_name,
		"stats": spec.tagline,
		"tags": starter.tags if starter else [],
		"body_bb": body,
	}


## Card data for a spell on the pick screen.
func spell_card(spell: SpellData) -> Dictionary:
	var school_color: Color = SpellTags.SCHOOL_COLORS.get(spell.school, Color.WHITE)
	var owned := SpellSystem.owned_rank(spell.family())
	var badge := ""
	var header: String = str(SpellTags.SCHOOL_LABELS.get(spell.school, "")).to_upper()
	if owned > 0:
		badge = "RANK UP"
		var old := SpellSystem.spells.filter(func(s): return s.family() == spell.family())
		if not old.is_empty():
			header = "UPGRADES %s" % old[0].display_name.to_upper()
	elif DraftSystem.school() != "" and spell.school != DraftSystem.school() and spell.school != "ANY":
		badge = "OTHER SCHOOL"
	return {
		"header": header, "header_color": school_color, "accent": school_color,
		"badge": badge,
		"badge_color": SpellTags.COMBO_COLOR if badge == "RANK UP" else Color(0.7, 0.66, 0.6),
		"icon": spell_icon(spell),
		"title": spell.display_name,
		"stats": spell.stats_line(),
		"tags": spell.tags,
		"body_bb": spell.description_bb(),
		"flavor": spell.flavor,
	}


# ── Rounds & contracts ─────────────────────────────────

func _show_party_choice() -> void:
	if GameManager.in_round:
		return
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
	round_label.text = ("Round %d · The Crimson Baron" if chosen.is_boss else "Round %d") % GameManager.current_round
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


## Small build stamp in the bottom-right corner (set by CI at export; "dev" locally),
## so a screenshot or bug report always says which build it came from.
func _add_build_label() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "dev"))
	print("Pythio %s" % version)
	var label := Label.new()
	label.name = "BuildLabel"
	label.text = version if version.begins_with("Build") else "Build: %s" % version
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.position -= Vector2(12, 8)
	label.z_index = 100
	add_child(label)


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
	_set_pose(spell.pose(), maxf(0.5, spell.cast_time + 0.3))
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
	if selected_spell and not SpellSystem.spells.has(selected_spell):
		selected_spell = null
	for i in SPELL_SLOTS:
		var key := SpellSystem.key_label_for_slot(i)
		if i < SpellSystem.spells.size():
			var spell: SpellData = SpellSystem.spells[i]
			var btn := _make_spell_slot(spell, "" if spell.is_passive() else key)
			if not spell.is_passive():
				btn.pressed.connect(func(): _on_spell_pressed(spell))
			spell_container.add_child(btn)
			spell_buttons.append(btn)
		else:
			spell_container.add_child(_make_empty_slot(key))


func spell_icon(spell: SpellData) -> Texture2D:
	var rel: String = SPELL_ICONS.get(spell.id, "")
	if rel == "":
		for tag in ["SHIELD", "HOT", "DIRECT", "DELAYED"]:
			if spell.tags.has(tag):
				rel = TAG_ICONS[tag]
				break
	if rel == "" and spell.icon:
		return spell.icon
	if rel == "":
		rel = FALLBACK_ICON
	return load(ART + rel) if ResourceLoader.exists(ART + rel) else spell.icon


func _make_spell_slot(spell: SpellData, key: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(104, 116)
	btn.focus_mode = Control.FOCUS_NONE   # so Q/W/E/R aren't swallowed by button focus
	btn.flat = true
	btn.tooltip_text = "%s%s\n%s\n%s%s" % [spell.display_name, ("  [%s]" % key) if key != "" else "",
		spell.stats_line(), spell.description_plain(),
		("\nTags: " + ", ".join(spell.tag_labels())) if not spell.tags.is_empty() else ""]

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = spell_icon(spell)
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
	if spell.is_passive():
		btn.add_child(_slot_label("Cost", "passive", 16, Color(1.0, 0.8, 0.35), Vector2(0, 84), HORIZONTAL_ALIGNMENT_CENTER))
	else:
		btn.add_child(_slot_label("Cost", str(int(spell.mana_cost)), 20, Color(1.0, 0.8, 0.35), Vector2(-6, 82), HORIZONTAL_ALIGNMENT_RIGHT))
	var name_lbl := _slot_label("Name", spell.display_name, 14, Color(0.92, 0.88, 0.8), Vector2(0, 116), HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.size = Vector2(104, 22)
	name_lbl.clip_text = true
	btn.add_child(name_lbl)
	var cd_label := _slot_label("CdText", "", 34, Color.WHITE, Vector2(0, 36), HORIZONTAL_ALIGNMENT_CENTER)
	btn.add_child(cd_label)
	return btn


func _make_empty_slot(key: String) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(104, 116)
	p.modulate = Color(1, 1, 1, 0.45)
	p.tooltip_text = "Empty — you'll pick a new spell for this slot every few rounds."
	p.add_child(_slot_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	p.add_child(_slot_label("Draft", "empty", 18, Color(0.6, 0.58, 0.55), Vector2(0, 44), HORIZONTAL_ALIGNMENT_CENTER))
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
		if i >= SpellSystem.spells.size():
			break
		var spell: SpellData = SpellSystem.spells[i]
		var btn := spell_buttons[i]
		if spell.is_passive():
			btn.modulate = Color.WHITE
			continue
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
	card_panel.close()
	game_over_panel.visible = true
	cast_bar.visible = false
	if GameManager.last_run_won:
		final_score_label.text = "Contract fulfilled.\nAll %d rounds survived.  Score: %d" % [round_reached, final_score]
		_set_pose("victory", 99.0)
		_say("victory", 6.0)
	else:
		final_score_label.text = "%s didn't make it in round %d.\nRounds survived: %d.  Score: %d" % [fallen_name if fallen_name != "" else "Someone", round_reached, round_reached - 1, final_score]
	score_label.text = "High Score: %d" % GameManager.high_score
	# Leaderboard entry
	_last_run = {"score": final_score, "round": maxi(1, round_reached), "won": GameManager.last_run_won}
	name_edit.text = Leaderboard.load_player_name()
	submit_button.disabled = false
	name_edit.editable = true
	submit_status.text = "Post your run to the marz.gg leaderboard."
	if GameManager.debug_used:
		submit_button.disabled = true
		name_edit.editable = false
		submit_status.text = "Debug panel used — this run can't be posted."


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
