class_name Game

extends Control

# ── Scene references ──
@onready var start_screen: Control       = $StartScreen
@onready var game_ui: Control            = $GameUI
@onready var header: Control             = $GameUI/Header
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
## Spellbook size: keys Q W E R. Empty slots wait for a spell pick.
const SPELL_SLOTS := 4
## Marks the Skip card among the pick options.
const SKIP := "__skip__"
## Baron pick with full passive slots: keep your passives and take a spell pick instead.
const BONUS_SPELL := "__bonus_spell__"
var spell_buttons: Array[Button] = []
var mana_label: Label
var cast_label: Label
var selected_spell: SpellData = null
var current_contract: ContractData
var fallen_name: String = ""
var _pose_reset_at := 0.0
var _orb_textures: Array = []   # mana orb, quarter by quarter (loaded once)
var _low_mana_warned := false
var _quip_tween: Tween
var _last_run := {"rounds": 0, "healing": 0}
var card_panel: Control
## Rules panel, passive tray, Cleanse and bandage counters (ui/HudCounters.gd).
var hud: HudCounters
## Screen shake, combo punch and the death veil (ui/ScreenFeel.gd).
var feel: ScreenFeel
## The top-10 list on the title screen, with ◀ ▶ between boards (ui/LeaderboardView.gd).
var leaderboard_view: LeaderboardView
var _banner: VBoxContainer
var _banner_tween: Tween
## What the open card screen is choosing: "spec" or "spell", and the options shown.
var _card_mode := ""
## Pythio comments on combos, but not every single one.
const COMBO_QUIP_GAP := 8.0
var _last_combo_quip := -100.0
var _card_options: Array = []
## The offer screen being shown (so "Back" from the swap screen can return to it).
var _last_offers: Array = []
## The spell pick came from the Baron's bounty ("A spell instead"), so it has no Skip either.
var _from_bounty := false
var _last_pick_round := 0
## The spell waiting to replace one of yours (swap screen).
var _pending_swap: SpellData = null


## The game fonts only cover letters and basic punctuation. Symbols such as ◀ ▶ ★ ■ □ ● ≤
## come from a tiny DejaVu subset. Desktop builds could borrow them from system fonts, but the
## web build has none, so without this they show as boxes.
const SYMBOL_FONT := "res://assets/fonts/symbols-dejavu-bold.ttf"
const GAME_FONTS := [
	"res://assets/fonts/oswald-latin-500-normal.woff2",
	"res://assets/fonts/oswald-latin-700-normal.woff2",
	"res://assets/fonts/pirata-one-latin-400-normal.woff2",
	"res://assets/fonts/special-elite-latin-400-normal.woff2",
]

static func add_symbol_fallback() -> void:
	var symbols: Font = load(SYMBOL_FONT)
	for path in GAME_FONTS:
		var font: Font = load(path)
		if font and symbols and not font.fallbacks.has(symbols):
			font.fallbacks = font.fallbacks + [symbols]


func _ready() -> void:
	add_symbol_fallback()
	ScreenFeel.load_setting()
	GameManager.game_over.connect(_on_game_over)
	# After a cleared round, "Job finished" holds first, then the next screen (owner, 2026-10-24).
	GameManager.show_party_choice.connect(func(): _after_job_finished(_show_party_choice))
	GameManager.show_spec_choice.connect(_show_spec_choice)
	GameManager.show_spell_pick.connect(func(offers, r): _after_job_finished(_show_spell_pick.bind(offers, r)))
	EventBus.round_cleared.connect(_on_round_cleared_transition)
	DraftSystem.build_complete.connect(func(): _say("build_complete", 5.0))
	EventBus.combo_fired.connect(_on_combo_fired)
	EffectSystem.effect_applied.connect(func(kind, _t, _v, _c): if kind == "mana": _flash_mana())
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
	Leaderboard.submitted.connect(_on_score_submitted)
	leaderboard_view = LeaderboardView.new(lb_grid, lb_status)
	add_child(leaderboard_view)
	Leaderboard.fetch_top()

	_add_build_label()
	hud = HudCounters.new()
	game_ui.add_child(hud)
	BandageSystem.channel_started.connect(_on_bandage_start)
	BandageSystem.channel_ended.connect(func(_t, _done): cast_bar.visible = SpellSystem.is_casting)
	DebuffSystem.first_seen.connect(func(kind): _say("debuff_" + kind, 5.0))
	_make_banner()
	EventBus.boss_phase.connect(_on_boss_phase)
	EventBus.rule_triggered.connect(func(kind, _t): if kind == "exhausted": _flash_exhausted())
	card_panel = preload("res://ui/CardChoicePanel.gd").new()
	game_ui.add_child(card_panel)
	card_panel.chosen.connect(_on_card_chosen)
	card_panel.back_pressed.connect(func(): _show_spell_pick(_last_offers, _last_pick_round))
	add_child(preload("res://ui/DebugPanel.gd").new())
	var pause_menu = preload("res://ui/PauseMenu.gd").new()
	pause_menu.can_open = func(): return game_ui.visible and not game_over_panel.visible
	pause_menu.restart_requested.connect(func():
		await _leave_run()
		_on_start_pressed())
	pause_menu.quit_requested.connect(func():
		await _leave_run()
		game_ui.visible = false
		start_screen.visible = true
		score_label.text = GameManager.best_text()
		Leaderboard.fetch_top())
	add_child(pause_menu)

	cast_label = _add_bar_label(cast_bar, 18)
	mana_label = _add_bar_label(mana_bar, 20)
	mana_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mana_label.position = Vector2(16, 12)
	mana_label.size = Vector2(336, 27)

	_pin_layout()
	feel = ScreenFeel.new()
	feel.name = "ScreenFeel"
	feel.stage = game_ui
	add_child(feel)
	game_ui.resized.connect(func(): _fit_party(party_container.get_child_count()))

	quip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quip_label.size = Vector2(quip_bubble.size.x - 112, quip_bubble.size.y - 60)   # stay inside the inked border

	score_label.text = GameManager.best_text()
	game_ui.visible = false
	cast_bar.visible = false
	party_choice_panel.visible = false
	start_screen.visible = true


## The window can be any shape (Steam Deck 16:10, ultrawide): keep each piece of the HUD on
## its own edge or in the middle (ui/ScreenLayout.gd). Positions stay the 1920x1080 ones.
func _pin_layout() -> void:
	var L := ScreenLayout
	for n in [$StartScreen/StartPythio, $StartScreen/LeaderboardPanel, $GameUI/GameOverPanel, _banner]:
		L.pin(n, L.CENTER, L.CENTER)
	L.pin(header, L.CENTER, L.TOP)
	L.pin(pythio_sprite, L.LEFT, L.BOTTOM)
	L.pin(quip_bubble, L.LEFT, L.BOTTOM)
	L.pin($GameUI/PlayerContainer, L.CENTER, L.BOTTOM)
	L.pin(spell_container, L.CENTER, L.BOTTOM)
	hud.pin_layout()


func _process(delta: float) -> void:
	if _pose_reset_at > 0.0 and Time.get_ticks_msec() / 1000.0 > _pose_reset_at and not SpellSystem.is_casting:
		_pose_reset_at = 0.0
		_set_pose("idle")

	if not GameManager.in_round:
		return

	timer_label.text = "" if GameManager.practice else "%.1fs" % GameManager.round_time
	_update_countdown()
	_update_mana_bar()
	if BandageSystem.is_channeling():
		cast_bar.value = BandageSystem.progress() * 100.0
	elif SpellSystem.is_casting and SpellSystem.current_spell:
		cast_bar.value = SpellSystem.cast_progress() * 100.0
		var left := SpellSystem.current_spell.cast_time - SpellSystem.cast_elapsed
		cast_label.text = "Casting %s  %.1fs" % [SpellSystem.current_spell.display_name, maxf(0.0, left)]
	_update_spell_ui()


## Mana came back (Divine Channel, Mana Conduit): a quick electric-blue pulse on the bar.
func _flash_mana() -> void:
	var tw := create_tween()
	mana_bar.modulate = Color(0.6, 0.85, 1.6)
	tw.tween_property(mana_bar, "modulate", Color.WHITE, 0.4)


func _on_combo_fired(_target, _label: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_combo_quip < COMBO_QUIP_GAP:
		return
	_last_combo_quip = now
	_say("combo", 2.5)


# ── "Job finished": the beat between a cleared round and the next screen ──
# Owner, 2026-10-24: players clicking at the end of a round picked a card and started the
# next round by accident. A short screen now holds (clicks and keys do nothing), then the
# pick or Next party screen opens, and that screen also ignores input for a moment.

var _job_finished: Control
var _job_finished_active := false
var _job_finished_next := Callable()
var _job_finished_id := 0


func _make_job_finished() -> void:
	_job_finished = Control.new()
	_job_finished.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_job_finished.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks
	_job_finished.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_job_finished.add_child(dim)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(1200, 0)
	box.position = Vector2(360, 380)
	box.size = Vector2(1200, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_job_finished.add_child(box)
	ScreenLayout.pin(box, ScreenLayout.CENTER, ScreenLayout.CENTER)
	var title := Label.new()
	title.name = "Title"
	title.text = "Job finished"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/pirata-one-latin-400-normal.woff2"))
	title.add_theme_font_size_override("font_size", 128)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	box.add_child(title)
	var sub := Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	box.add_child(sub)
	game_ui.add_child(_job_finished)


func _on_round_cleared_transition(round_num: int) -> void:
	if DifficultySystem.job_finished_time <= 0.0:
		return   # no hold (tests that fast-forward set it to 0)
	if not _job_finished:
		_make_job_finished()
	_job_finished_id += 1
	var my_id := _job_finished_id
	_job_finished_active = true
	_job_finished_next = Callable()
	_job_finished.get_node("Box/Sub").text = "Round %d cleared" % round_num
	game_ui.move_child(_job_finished, game_ui.get_child_count() - 1)
	_job_finished.visible = true
	_job_finished.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_job_finished, "modulate:a", 1.0, 0.2)
	_say("cleared", DifficultySystem.job_finished_time + 1.0)
	await get_tree().create_timer(DifficultySystem.job_finished_time, false).timeout   # holds while paused
	if my_id != _job_finished_id:
		return   # the run was left or a new transition started
	_job_finished_active = false
	_job_finished.visible = false
	var next := _job_finished_next
	_job_finished_next = Callable()
	if next.is_valid():
		next.call()


## Runs `next` now, or once the "Job finished" screen is done.
func _after_job_finished(next: Callable) -> void:
	if _job_finished_active:
		_job_finished_next = next
	else:
		next.call()


func _cancel_job_finished() -> void:
	_job_finished_id += 1
	_job_finished_active = false
	_job_finished_next = Callable()
	if _job_finished:
		_job_finished.visible = false


# ── Specialization and spell picks ─────────────────────

func _show_spec_choice() -> void:
	party_choice_panel.visible = false
	party_area.visible = false
	contract_info.visible = false
	header.visible = false   # the card screen has its own title (they used to overlap)
	round_label.text = "A new job"
	timer_label.text = "Choose your spell"
	_card_mode = "spec"
	_card_options = DraftSystem.specs.duplicate()
	var cards: Array = []
	for spec in _card_options:
		cards.append(PickCards.spec_card(spec))
	# Owner, 2026-10-24: players pick a spell, not a "school". The school still exists
	# underneath (it steers which spells you're offered) but is never named on screen.
	card_panel.show_cards("Choose your spell", "", cards)
	_say("spec", 5.0)


func _show_spell_pick(offers: Array, round_cleared: int) -> void:
	party_choice_panel.visible = false
	party_area.visible = false
	contract_info.visible = false
	header.visible = false
	round_label.text = ("Round %d cleared" % round_cleared) if round_cleared > 0 else "Bonus pick"
	_card_mode = "spell"
	if _last_pick_round != round_cleared:
		_from_bounty = false   # a new pick screen, not a return from "Replace which spell?"
	_last_offers = Array(offers)
	_last_pick_round = round_cleared
	_card_options = []   # untyped: it also holds the Skip marker
	_card_options.append_array(offers)
	# Phase E (owner, 2026-10-25): beating the Baron pays a passive. No Skip; with full
	# passive slots, a card lets you keep them and take a spell pick instead.
	var bounty := not offers.is_empty() and offers.all(func(o): return o.is_passive()) \
		and DraftSystem.pick_kind(round_cleared) == "passive"
	var title := "The Baron's bounty" if bounty else PickCards.pick_title(_card_options)
	timer_label.text = "Choose a passive" if bounty else title.replace("Add", "Pick")
	var cards: Array = []
	for spell in _card_options:
		cards.append(PickCards.spell_card(spell))
	if bounty:
		if DraftSystem.passives_full() and not DraftSystem.make_offers("spell").is_empty():
			_card_options.append(BONUS_SPELL)
			cards.append(PickCards.bonus_spell_card())
	elif not _from_bounty:
		_card_options.append(SKIP)
		cards.append(PickCards.skip_card())
	var sub := ""
	if bounty:
		sub = "A passive works on its own for the rest of the run. Passives %d / %d" % [
			SpellSystem.passives.size(), DraftSystem.passive_cap]
		if DraftSystem.passives_full():
			sub += " — full: a new one replaces one of yours"
		sub += "."
	else:
		sub = "Spells %d / %d" % [SpellSystem.spells.size(), DraftSystem.spellbook_cap]
		if DraftSystem.spells_full():
			sub += " — full: a new one replaces one of yours."
		sub += "."
	sub += " " + PickCards.next_pick_text(round_cleared)
	card_panel.show_cards(title, sub, cards)
	_say("bounty" if bounty else "pick", 4.0)


## Second step when your bar is full: which spell does the new one replace?
func _show_swap(spell: SpellData) -> void:
	_card_mode = "swap"
	_pending_swap = spell
	var row: Array = SpellSystem.passives if spell.is_passive() else SpellSystem.spells
	_card_options = row.duplicate()
	var cards: Array = []
	for i in _card_options.size():
		var c := PickCards.spell_card(_card_options[i])
		var key := "" if spell.is_passive() else SpellSystem.key_label_for_slot(i)
		c.header = ("YOUR %s  [%s]" % ["PASSIVE" if spell.is_passive() else "SPELL", key]) if key != "" else "YOUR PASSIVE"
		c.badge = "REPLACE"
		c.badge_color = Color(0.95, 0.35, 0.3)
		c.hint_bb = ""
		cards.append(c)
	card_panel.show_cards("Replace which %s?" % ("passive" if spell.is_passive() else "spell"),
		"%s takes its slot%s." % [spell.display_name, "" if spell.is_passive() else " and its key"], cards, "Back to the offers")


func _on_card_chosen(index: int) -> void:
	var choice = _card_options[index]
	match _card_mode:
		"spec":
			DraftSystem.choose_spec(choice)
		"spell":
			if typeof(choice) == TYPE_STRING and choice == BONUS_SPELL:
				var spells := DraftSystem.make_offers("spell")
				if not spells.is_empty():
					_from_bounty = true   # the Baron's bounty has no Skip (Phase E)
					_show_spell_pick(spells, _last_pick_round)
					return
			elif typeof(choice) == TYPE_STRING and choice == SKIP:
				DraftSystem.skip()
				_say("skip", 3.0)
			elif DraftSystem.needs_swap(choice):
				_show_swap(choice)
				return
			else:
				DraftSystem.take(choice)
		"swap":
			DraftSystem.swap(choice, _pending_swap)
			_pending_swap = null
		"first_time":
			_card_mode = ""
			PracticeRound.mark_asked()
			if index == 0:
				_start_practice()
			else:
				_on_start_pressed()
			return
	_card_mode = ""
	_from_bounty = false
	GameManager.continue_to_contracts()


# ── Boss phase banner (blood red = danger) ─────────────

func _make_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.position = Vector2(360, 672)   # between the fighters and the spell bar
	_banner.custom_minimum_size = Vector2(1200, 0)
	_banner.size = Vector2(1200, 120)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/pirata-one-latin-400-normal.woff2"))
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.22, 0.16))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_child(title)
	var hint := Label.new()
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_constant_override("outline_size", 6)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_child(hint)
	game_ui.add_child(_banner)


func _on_boss_phase(phase: int, title: String, hint: String) -> void:
	_banner.get_node("Title").text = "%s · %s" % ["I".repeat(phase) if phase < 4 else str(phase), title]
	_banner.get_node("Hint").text = hint
	_banner.visible = true
	_banner.modulate.a = 1.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(2.6)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)
	_banner_tween.tween_callback(func(): _banner.visible = false)
	if phase == 3:
		_say("boss", 3.0)


# ── Around the HUD counters (the counters themselves: ui/HudCounters.gd) ──

func _flash_exhausted() -> void:
	var tw := create_tween()
	mana_bar.modulate = Color(0.55, 0.55, 0.6)
	tw.tween_property(mana_bar, "modulate", Color.WHITE, 0.6)


func _on_bandage_start(target: Node, _duration: float) -> void:
	_set_pose("cast_heal", BandageSystem.channel_time + 0.3)
	cast_bar.visible = true
	cast_bar.value = 0
	cast_label.text = "Bandaging %s" % target.display_name


# ── Rounds & contracts ─────────────────────────────────

func _show_party_choice() -> void:
	if GameManager.in_round:
		return
	party_choice_panel.visible = true
	party_choice_panel.guard_input()
	party_area.visible = false
	contract_info.visible = false
	var contracts = contract_selector.get_contracts_for_round(GameManager.current_round)
	party_choice_panel.setup_contracts(contracts)
	header.visible = true
	round_label.text = "Round %d" % GameManager.current_round
	timer_label.text = ""   # the panel says "Next party" right below (they used to overlap)


func _on_contract_chosen(chosen: ContractData) -> void:
	current_contract = chosen
	party_choice_panel.visible = false
	await _clear_party_container()

	contract_name_label.text = chosen.contract_name.replace("  ", " ")
	contract_risk_label.text = "PARTY OF %d" % chosen.unit_templates.size()
	contract_info.visible = true
	header.visible = true
	round_label.text = ("Round %d · The Crimson Baron" if chosen.is_boss else "Round %d") % GameManager.current_round
	round_label.modulate = Color(1, 0.35, 0.3) if chosen.is_boss else Color.WHITE

	_low_mana_warned = false
	GameManager.start_round(chosen)
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
	var screen := game_ui.size if game_ui.size.x > 0.0 else ScreenLayout.DESIGN
	var avail := 1800.0
	var s := minf(1.0, avail / maxf(needed, 1.0))
	party_area.size.x = maxf(avail, needed)
	party_area.scale = Vector2(s, s)
	# Centred on the real screen, which can be wider or taller than 1920x1080.
	party_area.position.x = (screen.x - party_area.size.x * s) / 2.0
	party_area.position.y = 230.0 + (1.0 - s) * 300.0 + (screen.y - ScreenLayout.DESIGN.y) / 2.0


func _clear_party_container() -> void:
	TargetSystem.clear_targets()
	for child in party_container.get_children():
		child.queue_free()
	await get_tree().process_frame


# ── Final seconds: the timer flashes and pops on each second (owner, 2026-10-24) ──
var _countdown_sec := -1


func _update_countdown() -> void:
	var left := GameManager.round_time
	if GameManager.practice or left > DifficultySystem.final_countdown_time or left <= 0.0:
		_reset_countdown()
		return
	timer_label.pivot_offset = timer_label.size / 2.0
	# Flash: bright for the first half of each second, normal for the second half.
	var bright := fmod(left, 1.0) > 0.5
	timer_label.modulate = Color(1.9, 1.7, 1.7) if bright else Color.WHITE
	var sec := ceili(left)
	if sec != _countdown_sec:
		_countdown_sec = sec
		timer_label.scale = Vector2.ONE * 1.6
		var tw := create_tween()
		tw.tween_property(timer_label, "scale", Vector2.ONE * 1.15, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _reset_countdown() -> void:
	if _countdown_sec == -1:
		return
	_countdown_sec = -1
	timer_label.scale = Vector2.ONE
	timer_label.modulate = Color.WHITE


func _on_round_ended(_round_num: int) -> void:
	_reset_countdown()
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
	if GameManager.exhausted_time > 0.0 and GameManager.in_round:
		mana_label.text += "   EXHAUSTED %.0fs" % ceilf(GameManager.exhausted_time)
	var frac := GameManager.mana / maxf(1.0, GameManager.max_mana)
	var orb := clampi(int(ceil(frac * 4.0)), 1, 4)
	if _orb_textures.is_empty():
		for i in range(1, 5):
			_orb_textures.append(load(ART + "ui/bars/mana_orb_%d.png" % i))
	var tex = _orb_textures[orb - 1]
	if tex and mana_orb.texture != tex:
		mana_orb.texture = tex
	if GameManager.in_round and frac < 0.2 and not _low_mana_warned:
		_low_mana_warned = true
		_set_pose("low_mana", 2.0)
		_say("low_mana")
		SoundSystem.low_mana()


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
	icon.texture = PickCards.spell_icon(spell)
	if spell.is_passive():
		icon.modulate = Color(1.0, 0.85, 0.45)   # gold-tinted: always on, no key
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	# Gold frame that pulses when casting this on the hovered fighter would fire a combo.
	var glow := Panel.new()
	glow.name = "Glow"
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(1.0, 0.82, 0.3, 0.12)
	gs.border_color = Color(1.0, 0.82, 0.3)
	gs.set_border_width_all(4)
	gs.set_corner_radius_all(6)
	gs.shadow_color = Color(1.0, 0.75, 0.2, 0.55)
	gs.shadow_size = 10
	glow.add_theme_stylebox_override("panel", gs)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	btn.add_child(glow)

	var cd := ColorRect.new()
	cd.name = "Cooldown"
	cd.color = Color(0, 0, 0, 0.65)
	cd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.visible = false
	btn.add_child(cd)

	btn.add_child(HudCounters.make_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	if spell.is_passive():
		btn.add_child(HudCounters.make_label("Cost", "passive", Palette.MIN_FONT, Palette.COMBO, Vector2(0, 84), HORIZONTAL_ALIGNMENT_CENTER))
	else:
		btn.add_child(HudCounters.make_label("Cost", str(int(spell.mana_cost)), 20, Palette.MANA, Vector2(-6, 82), HORIZONTAL_ALIGNMENT_RIGHT))
		# Cast time on the button too (owner, 2026-10-24): "inst" or "1.5s", bottom left.
		var cast_txt := "inst" if spell.cast_time <= 0.0 else "%ss" % SpellData._num(spell.cast_time)
		var cast_lbl := HudCounters.make_label("Cast", cast_txt, Palette.MIN_FONT, Palette.BONE, Vector2(6, 84), HORIZONTAL_ALIGNMENT_LEFT)
		cast_lbl.add_theme_constant_override("outline_size", 5)
		cast_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_child(cast_lbl)
	var name_lbl := HudCounters.make_label("Name", spell.display_name, Palette.MIN_FONT, Palette.SEPIA, Vector2(-6, 114), HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.size = Vector2(116, 26)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS   # full name in the tooltip
	btn.add_child(name_lbl)
	var cd_label := HudCounters.make_label("CdText", "", 34, Color.WHITE, Vector2(0, 36), HORIZONTAL_ALIGNMENT_CENTER)
	btn.add_child(cd_label)
	return btn


func _make_empty_slot(key: String) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(104, 116)
	p.modulate = Color(1, 1, 1, 0.45)
	p.tooltip_text = "Empty — you'll pick a new spell for this slot every few rounds."
	p.add_child(HudCounters.make_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	p.add_child(HudCounters.make_label("Draft", "empty", Palette.MIN_FONT, Palette.SEPIA, Vector2(0, 44), HORIZONTAL_ALIGNMENT_CENTER))
	return p


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
		var glow := btn.get_node_or_null("Glow")
		if glow:
			var t = SpellSystem.hovered_target
			var ready := castable and is_instance_valid(t) and EffectSystem.would_combo(spell, t)
			glow.visible = ready
			if ready:
				glow.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() / 1000.0 * 8.0)
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
	var path := ART + "characters/pythio/pythio_%s.png" % pose
	var tex = load(path) if ResourceLoader.exists(path) else null
	if tex:
		pythio_sprite.texture = tex
	_pose_reset_at = (Time.get_ticks_msec() / 1000.0 + hold) if hold > 0.0 else 0.0


func _say(kind: String, seconds: float = 3.5) -> void:
	var lines: Array = PythioLines.QUIPS.get(kind, [])
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

# ── First time on the job? (owner, 2026-10-24) ─────────
# Take the Job asks once per device. Yes → a practice round (scenes/practice.gd), then the
# real run. Tests call _on_start_pressed() directly, so they never see the question.

var _practice: PracticeRound


func _on_take_job_pressed() -> void:
	if PracticeRound.was_asked():
		_on_start_pressed()
		return
	start_screen.visible = false
	game_ui.visible = true
	_set_pose("idle")
	# Nothing from a previous run (or the scene's placeholders) behind the question.
	SpellSystem.set_spellbook_ids(PackedStringArray([]))
	_create_spell_buttons()
	contract_info.visible = false
	party_area.visible = false
	round_label.text = ""
	timer_label.text = ""
	header.visible = false
	_card_mode = "first_time"
	_card_options = ["yes", "no"]
	card_panel.show_cards("First time on the job?", "", [
		{"header": "PRACTICE", "header_color": Color(0.49, 0.95, 0.35), "accent": Color(0.49, 0.95, 0.35),
			"title": "Yes, show me",
			"body_bb": "A short practice round: one knight, one spell. Then the real job starts.",
			"flavor": "Everybody bleeds their first day."},
		{"header": "STRAIGHT IN", "header_color": Color(0.85, 0.82, 0.76), "accent": Color(0.85, 0.82, 0.76),
			"title": "No, I know the work",
			"body_bb": "Skip the practice and start a run.",
			"flavor": "Suit yourself."},
	])


func _start_practice() -> void:
	header.visible = true
	_practice = PracticeRound.new(self)
	add_child(_practice)
	_practice.finished.connect(func():
		_practice = null
		await _clear_party_container()
		contract_info.visible = false
		_on_start_pressed())
	_practice.begin()


func _on_start_pressed() -> void:
	start_screen.visible = false
	game_ui.visible = true
	_set_pose("idle")
	_create_spell_buttons()
	GameManager.new_game()


## The game-over stats: rounds, effective healing and the skill numbers behind it.
func run_summary() -> String:
	var spells := ", ".join(SpellSystem.spells.map(func(s): return s.display_name))
	var passives := ", ".join(SpellSystem.passives.map(func(s): return s.display_name))
	return "Rounds survived: %d   ·   Effective healing: %s\nOverheal %d%%  ·  Mitigated %s  ·  Combos %d  ·  Bandages %d\n%s%s" % [
		GameManager.rounds_survived(), RunStats.fmt(RunStats.effective_healing()),
		RunStats.overheal_percent(), RunStats.fmt(RunStats.mitigated()), RunStats.combos, RunStats.bandages,
		spells, ("  |  " + passives) if passives != "" else ""]


func _on_game_over(round_reached: int) -> void:
	party_choice_panel.visible = false
	card_panel.close()
	game_over_panel.visible = true
	cast_bar.visible = false
	final_score_label.text = "%s didn't make it in round %d.\n%s" % [fallen_name if fallen_name != "" else "Someone", round_reached, run_summary()]
	score_label.text = GameManager.best_text()
	# Leaderboard entry
	_last_run = {"rounds": GameManager.rounds_survived(), "healing": RunStats.effective_healing()}
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
	Leaderboard.submit(player, _last_run.rounds, _last_run.healing)


func _on_score_submitted(ok: bool, rank: int, entries: Array, message: String) -> void:
	if ok:
		submit_status.text = "Posted. You're #%d on the board." % rank
		leaderboard_view.show_board(true, entries)
	else:
		submit_status.text = message
		submit_button.disabled = false
		name_edit.editable = true


## Pause menu: end the current run quietly (no game over, nothing posted) and clear the screen.
func _leave_run() -> void:
	if _practice:
		_practice.cancel()
		_practice = null
	_cancel_job_finished()
	GameManager.abandon_run()
	party_choice_panel.visible = false
	card_panel.close()
	_card_mode = ""
	_from_bounty = false
	game_over_panel.visible = false
	feel.clear()
	cast_bar.visible = false
	fallen_name = ""
	round_label.modulate = Color.WHITE
	header.visible = true
	_set_pose("idle")
	await _clear_party_container()


func _on_play_again_pressed() -> void:
	game_over_panel.visible = false
	feel.clear()
	fallen_name = ""
	round_label.modulate = Color.WHITE
	header.visible = true
	_set_pose("idle")
	await _clear_party_container()
	GameManager.new_game()
