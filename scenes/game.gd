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
## Spellbook size: keys Q W E R. Empty slots wait for a spell pick.
const SPELL_SLOTS := 4
## Marks the Skip card among the pick options.
const SKIP := "__skip__"
## Baron pick with full passive slots: keep your passives and take a spell pick instead.
const BONUS_SPELL := "__bonus_spell__"
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
## Which tag picks a spell's icon when it has several (first match wins).
const TAG_ORDER := ["SHIELD", "PROTECT", "HOT", "DELAYED", "MULTI", "DIRECT", "CLEANSE"]

## Pythio's dry one-liners. Edit freely.
const QUIPS := {
	"round_start": ["Hold still. This stings less than dying.", "Everyone breathing? Keep it that way.",
		"I charge by the hour. Try not to bleed by the minute.", "Another job. Same blood."],
	"boss": ["The Baron. Of course it's the Baron.", "Big man, big wounds, big invoice."],
	"low_mana": ["Running on fumes.", "Pace yourselves. I'm not a fountain."],
	"death": ["Well. That's a refund I won't be getting.", "Should've ducked."],
	"victory": ["Contract fulfilled. Nobody died. Mostly.", "Pay up. I take coin, not thanks."],
	"spec": ["Every healer starts somewhere. Pick your first spell.", "Choose how you'll keep them breathing."],
	"pick": ["New trick. Try not to waste it.", "The job pays in spells. Pick one."],
	"bounty": ["The Baron pays well. Spend it wisely.", "He lived. Now I get paid properly.", "Hazard pay. Make it count."],
	"combo": ["Now that's teamwork.", "Two spells, one invoice.", "Elegant. Expensive, but elegant.",
		"Put that on the bill.", "That's how it's done."],
	"practice_start": ["One knight, one spell. Let's warm up."],
	"practice_done": ["That's the trade. Now let's get paid."],
	"cleared": ["Paid in full. Mostly.", "Everyone's still breathing. Invoice sent.",
		"Another job done. Another ache.", "Nobody died. I'll take it."],
	# First time each debuff shows up in a run (Phase F): Pythio says what to do.
	"debuff_POISON": ["Poison. Press F to Cleanse it before it stacks."],
	"debuff_BLEED": ["A bleeder. Cleanse won't help: heal him above 80%, or bandage."],
	"debuff_HEX": ["Hexed. Heals do half on him. Cleanse it (F), or shield him."],
	"debuff_DREAD": ["Dread. If he drops to that line, he's gone. Cleanse it (F)."],
	"skip": ["Saving it for later. Bold.", "Fine. More mana, fewer surprises."],
	"build_complete": ["That's a full kit. From here, every new trick costs an old one.", "Bag's full. Now let's see how far it goes."],
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
var _passive_tray: HBoxContainer
var _bandage_label: RichTextLabel
var _cleanse_label: RichTextLabel
var _rules_box: VBoxContainer
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
	GameManager.game_over.connect(_on_game_over)
	# After a cleared round, "Job finished" holds first, then the next screen (owner, 2026-10-24).
	GameManager.show_party_choice.connect(func(): _after_job_finished(_show_party_choice))
	GameManager.show_spec_choice.connect(_show_spec_choice)
	GameManager.show_spell_pick.connect(func(offers, r): _after_job_finished(_show_spell_pick.bind(offers, r)))
	EventBus.round_cleared.connect(_on_round_cleared_transition)
	DraftSystem.build_complete.connect(func(): _say("build_complete", 5.0))
	EventBus.combo_fired.connect(_on_combo_fired)
	EffectSystem.effect_applied.connect(func(kind, _t, _v, _c): if kind == "mana": _flash_mana())
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
	_make_board_nav()
	Leaderboard.fetch_top()

	_add_build_label()
	_make_passive_tray()
	_make_bandage_counter()
	_make_cleanse_counter()
	_make_rules_panel()
	_make_banner()
	EventBus.boss_phase.connect(_on_boss_phase)
	SpellSystem.spellbook_changed.connect(_refresh_rules_panel)
	EventBus.rule_triggered.connect(func(kind, _t): if kind == "exhausted": _flash_exhausted())
	SpellSystem.spellbook_changed.connect(_refresh_passive_tray)
	EventBus.passive_triggered.connect(_pulse_passive)
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

	quip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quip_label.size = Vector2(quip_bubble.size.x - 112, quip_bubble.size.y - 60)   # stay inside the inked border

	score_label.text = GameManager.best_text()
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

	timer_label.text = "" if GameManager.practice else "%.1fs" % GameManager.round_time
	_update_countdown()
	GameManager.round_time -= delta
	if GameManager.round_time <= 0:
		GameManager.round_time = 0
		GameManager.end_round(true)
		return

	GameManager.regen_mana(delta)
	_update_mana_bar()
	if BandageSystem.is_channeling():
		cast_bar.value = BandageSystem.progress() * 100.0
	elif SpellSystem.is_casting and SpellSystem.current_spell:
		cast_bar.value = SpellSystem.cast_progress() * 100.0
		var left := SpellSystem.current_spell.cast_time - SpellSystem.cast_elapsed
		cast_label.text = "Casting %s  %.1fs" % [SpellSystem.current_spell.display_name, maxf(0.0, left)]
	_update_spell_ui()
	_pulse_cleanse()


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
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_job_finished.add_child(box)
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
	round_label.text = "A new job"
	timer_label.text = "Choose your spell"
	_card_mode = "spec"
	_card_options = DraftSystem.specs.duplicate()
	var cards: Array = []
	for spec in _card_options:
		cards.append(spec_card(spec))
	# Owner, 2026-10-24: players pick a spell, not a "school". The school still exists
	# underneath (it steers which spells you're offered) but is never named on screen.
	card_panel.show_cards("Choose your spell", "", cards)
	_say("spec", 5.0)


func _show_spell_pick(offers: Array, round_cleared: int) -> void:
	party_choice_panel.visible = false
	party_area.visible = false
	contract_info.visible = false
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
	var title := "The Baron's bounty" if bounty else pick_title(_card_options)
	timer_label.text = "Choose a passive" if bounty else title.replace("Add", "Pick")
	var cards: Array = []
	for spell in _card_options:
		cards.append(spell_card(spell))
	if bounty:
		if DraftSystem.passives_full() and not DraftSystem.make_offers("spell").is_empty():
			_card_options.append(BONUS_SPELL)
			cards.append(bonus_spell_card())
	elif not _from_bounty:
		_card_options.append(SKIP)
		cards.append(skip_card())
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
	sub += " " + next_pick_text(round_cleared)
	card_panel.show_cards(title, sub, cards)
	_say("bounty" if bounty else "pick", 4.0)


## "Next: a spell after round 7." / "Next: the Baron's passive after round 10."
static func next_pick_text(after: int) -> String:
	var r := after + 1
	while DraftSystem.pick_kind(r) == "" and r < after + 1000:
		r += 1
	if DraftSystem.pick_kind(r) == "passive":
		return "Next: the Baron's passive after round %d." % r
	return "Next pick after round %d." % r


## The Baron pick's extra card when your passive slots are full.
func bonus_spell_card() -> Dictionary:
	var grey := Color(0.7, 0.66, 0.6)
	return {
		"header": "INSTEAD", "header_color": grey, "accent": grey,
		"title": "A spell instead",
		"stats": "Keep your passives",
		"stats_color": Color(0.8, 0.76, 0.7),
		"body_bb": "Keep the passives you have and pick a new spell (or a rank-up) instead.",
		"flavor": "Cash, not credit.",
	}


## Second step when your bar is full: which spell does the new one replace?
func _show_swap(spell: SpellData) -> void:
	_card_mode = "swap"
	_pending_swap = spell
	var row: Array = SpellSystem.passives if spell.is_passive() else SpellSystem.spells
	_card_options = row.duplicate()
	var cards: Array = []
	for i in _card_options.size():
		var c := spell_card(_card_options[i])
		var key := "" if spell.is_passive() else SpellSystem.key_label_for_slot(i)
		c.header = ("YOUR %s  [%s]" % ["PASSIVE" if spell.is_passive() else "SPELL", key]) if key != "" else "YOUR PASSIVE"
		c.badge = "REPLACE"
		c.badge_color = Color(0.95, 0.35, 0.3)
		c.hint_bb = ""
		cards.append(c)
	card_panel.show_cards("Replace which %s?" % ("passive" if spell.is_passive() else "spell"),
		"%s takes its slot%s." % [spell.display_name, "" if spell.is_passive() else " and its key"], cards, "Back to the offers")


## "Add a spell", "Add a passive" or "Add a spell or passive", depending on what's offered.
static func pick_title(offers: Array) -> String:
	var passives := offers.filter(func(s): return s.is_passive()).size()
	if passives == 0:
		return "Add a spell"
	if passives == offers.size():
		return "Add a passive"
	return "Add a spell or passive"


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


## Card data for a starter spell on the first pick ("Choose your spell"). It reads like
## any spell card: name, cast time, cost, one sentence.
func spec_card(spec: SpecData) -> Dictionary:
	var color: Color = SpellTags.SCHOOL_COLORS.get(spec.school, Color.WHITE)
	var starter := spec.starter
	if not starter:
		return {"title": spec.display_name, "accent": color}
	return {
		"accent": color,
		"icon": spell_icon(starter),
		"title": starter.display_name,
		"cast": starter.cast_badge(),
		"stats": starter.cost_line(),
		"tags": starter.tags,
		"body_bb": starter.description_bb(),
	}


## The Skip card: pass on this pick for a little extra max mana.
func skip_card() -> Dictionary:
	var grey := Color(0.7, 0.66, 0.6)
	return {
		"header": "PASS", "header_color": grey, "accent": grey,
		"title": "Skip",
		"stats": "+%d max mana for the rest of the run" % roundi(DraftSystem.skip_bonus_max_mana),
		"body_bb": "Keep your build as it is. Nothing new to learn, a little more to spend.",
		"flavor": "Sometimes the best trick is the one you already know.",
	}


## Card data for a spell on the pick screen.
func spell_card(spell: SpellData) -> Dictionary:
	var school_color: Color = SpellTags.SCHOOL_COLORS.get(spell.school, Color.WHITE)
	var owned := SpellSystem.owned_rank(spell.family())
	var badge := ""
	var header := ""   # no school names on screen (owner, 2026-10-24)
	if owned > 0:
		badge = "RANK UP"
		var old := SpellSystem.all_owned().filter(func(s): return s.family() == spell.family())
		if not old.is_empty():
			header = "UPGRADES %s" % old[0].display_name.to_upper()
	elif DraftSystem.needs_swap(spell):
		badge = "SWAP"
	return {
		"header": header, "header_color": school_color, "accent": school_color,
		"badge": badge,
		"badge_color": SpellTags.COMBO_COLOR if badge == "RANK UP" else Color(0.7, 0.66, 0.6),
		"icon": spell_icon(spell),
		"title": spell.display_name,
		"cast": spell.cast_badge(),
		"stats": spell.cost_line(),
		"stats_color": SpellTags.COMBO_COLOR if spell.is_passive() else (DebuffStatus.VIOLET if spell.utility else SpellTags.MANA_COLOR),
		"tags": spell.tags,
		"body_bb": spell.description_bb(),
		"hint_bb": synergy_hint_bb(spell) + (("\n" if synergy_hint_bb(spell) != "" else "") + "[color=#c9c2b6][i]Your %s are full: you'll choose one to replace.[/i][/color]" % ("passives" if spell.is_passive() else "spells") if badge == "SWAP" else ""),
		"flavor": spell.flavor,
	}


## Gold "★ Combos with Renew" lines for a pick card (empty if it doesn't connect).
func synergy_hint_bb(spell: SpellData) -> String:
	var syn := DraftSystem.synergy(spell)
	var gold := SpellTags.COMBO_COLOR.to_html(false)
	var tag_words := ", ".join(syn.tags.map(func(t): return SpellTags.label(t)))
	var lines: Array[String] = []
	if not syn.with.is_empty():
		lines.append("★ Combos with [b]%s[/b]" % ", ".join(syn.with.map(func(s): return s.display_name)))
	if not syn.from.is_empty():
		lines.append("★ Your [b]%s[/b] combos with this" % ", ".join(syn.from.map(func(s): return s.display_name)))
	if lines.is_empty():
		return ""
	return "[color=#%s]%s[/color]\n[color=#%s][i]via %s[/i][/color]" % [gold, "\n".join(lines), Color(gold, 0.7).to_html(false), tag_words]


# ── Boss phase banner (blood red = danger) ─────────────

func _make_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.position = Vector2(360, 672)   # between the fighters and the spell bar
	_banner.custom_minimum_size = Vector2(1200, 0)
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


# ── Battlefield rules: always on screen, top right ─────

func _make_rules_panel() -> void:
	_rules_box = VBoxContainer.new()
	_rules_box.position = Vector2(1530, 28)
	_rules_box.custom_minimum_size = Vector2(370, 0)
	_rules_box.add_theme_constant_override("separation", 2)
	game_ui.add_child(_rules_box)
	_refresh_rules_panel()


func _refresh_rules_panel() -> void:
	if not _rules_box:
		return
	for c in _rules_box.get_children():
		_rules_box.remove_child(c)
		c.queue_free()
	var title := _slot_label("RulesTitle", "BATTLEFIELD RULES", 15, Color(0.95, 0.35, 0.3, 0.85), Vector2.ZERO, HORIZONTAL_ALIGNMENT_RIGHT)
	title.custom_minimum_size = Vector2(370, 20)
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.tooltip_text = "Rules everyone plays by. Some passives cancel a rule (shown in gold)."
	_rules_box.add_child(title)
	for rule in EffectSystem.battlefield_rules:
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.custom_minimum_size = Vector2(370, 0)
		line.add_theme_font_size_override("normal_font_size", 17)
		line.add_theme_font_size_override("bold_font_size", 17)
		var by := EffectSystem.cancelled_by(rule.rule_id)
		if by:
			line.text = "[right][color=#6f6a63][s]%s[/s][/color]  [color=#ffd24d]→ %s[/color][/right]" % [rule.rule_name, by.display_name]
			line.tooltip_text = "%s is cancelled by your %s:\n%s" % [rule.rule_name, by.display_name, by.description_plain()]
		else:
			line.text = "[right][color=#d9d2c5]%s[/color][/right]" % rule.rule_name
			line.tooltip_text = "%s: %s" % [rule.rule_name, SpellTags.fill_plain(rule.describe())]
		_rules_box.add_child(line)


func _flash_exhausted() -> void:
	var tw := create_tween()
	mana_bar.modulate = Color(0.55, 0.55, 0.6)
	tw.tween_property(mana_bar, "modulate", Color.WHITE, 0.6)


# ── Bandages: counter by the mana bar, cast bar while channelling ──

func _make_bandage_counter() -> void:
	_bandage_label = RichTextLabel.new()
	_bandage_label.bbcode_enabled = true
	_bandage_label.fit_content = true
	_bandage_label.scroll_active = false
	_bandage_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_bandage_label.tooltip_text = "Bandages: hover a fighter and press Space to channel %d healing over %ss.\nYou can't cast while bandaging. +1 bandage every %d rounds (max %d)." % [
		int(BandageSystem.heal_total), str(BandageSystem.channel_time), BandageSystem.gain_every_rounds, BandageSystem.max_charges]
	_bandage_label.add_theme_font_size_override("normal_font_size", 20)
	_bandage_label.add_theme_font_size_override("bold_font_size", 20)
	_bandage_label.position = Vector2(1420, 1008)
	_bandage_label.size = Vector2(300, 34)
	game_ui.add_child(_bandage_label)
	BandageSystem.charges_changed.connect(func(_c, _m): _update_bandages())
	BandageSystem.channel_started.connect(_on_bandage_start)
	BandageSystem.channel_ended.connect(func(_t, _done): cast_bar.visible = SpellSystem.is_casting)
	BandageSystem.bandage_failed.connect(_on_bandage_failed)
	_update_bandages()


func _update_bandages() -> void:
	var full := "■".repeat(BandageSystem.charges)
	var empty := "□".repeat(maxi(0, BandageSystem.max_charges - BandageSystem.charges))
	_bandage_label.text = "[b]BANDAGES[/b]  [color=#7df25a]%s[/color][color=#5a554e]%s[/color]  [color=#a9a39a]Space[/color]" % [full, empty]


func _on_bandage_start(target: Node, _duration: float) -> void:
	_set_pose("cast_heal", BandageSystem.channel_time + 0.3)
	cast_bar.visible = true
	cast_bar.value = 0
	cast_label.text = "Bandaging %s" % target.display_name


func _on_bandage_failed(reason: String) -> void:
	if reason == "no_charges":
		var tw := create_tween()
		_bandage_label.modulate = Color(1.0, 0.3, 0.3)
		tw.tween_property(_bandage_label, "modulate", Color.WHITE, 0.4)


# ── Cleanse (Phase F): counter above the bandages; F on a hovered fighter ──
const VIOLET_HEX := "b873ff"

func _make_cleanse_counter() -> void:
	_cleanse_label = RichTextLabel.new()
	_cleanse_label.bbcode_enabled = true
	_cleanse_label.fit_content = true
	_cleanse_label.scroll_active = false
	_cleanse_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_cleanse_label.add_theme_font_size_override("normal_font_size", 20)
	_cleanse_label.add_theme_font_size_override("bold_font_size", 20)
	_cleanse_label.position = Vector2(1420, 970)
	_cleanse_label.size = Vector2(320, 34)
	game_ui.add_child(_cleanse_label)
	CleanseSystem.charges_changed.connect(func(_c, _m): _update_cleanse())
	SpellSystem.spellbook_changed.connect(_update_cleanse)
	CleanseSystem.cleanse_failed.connect(func(reason):
		if reason == "no_charges":
			var tw := create_tween()
			_cleanse_label.modulate = Color(1.0, 0.3, 0.3)
			tw.tween_property(_cleanse_label, "modulate", Color.WHITE, 0.4))
	DebuffSystem.first_seen.connect(func(kind): _say("debuff_" + kind, 5.0))
	_update_cleanse()


func _update_cleanse() -> void:
	var sp := CleanseSystem.spell()
	if not sp:
		_cleanse_label.text = ""
		return
	var full := "◆".repeat(CleanseSystem.charges)
	var empty := "◇".repeat(maxi(0, CleanseSystem.max_charges() - CleanseSystem.charges))
	_cleanse_label.text = "[b]%s[/b]  [color=#%s]%s[/color][color=#5a554e]%s[/color]  [color=#a9a39a]F[/color]" % [
		sp.display_name.to_upper(), VIOLET_HEX, full, empty]
	_cleanse_label.tooltip_text = "%s: point at a fighter and press F. %s\nFree and instant; charges come back during the round (one every %ss)." % [
		sp.display_name, sp.description_plain(), str(sp.charge_time)]


## The counter glows violet when F on the hovered fighter would remove something.
func _pulse_cleanse() -> void:
	if not _cleanse_label:
		return
	var helps := GameManager.in_round and CleanseSystem.would_help(SpellSystem.hovered_target)
	var t := Time.get_ticks_msec() / 1000.0
	_cleanse_label.modulate = Color(1.25 + 0.35 * sin(t * 8.0), 0.95, 1.45) if helps else Color.WHITE


# ── Passive tray: 3 gold slots next to the spell bar ───

const TRAY_SLOT := Vector2(84, 84)

func _make_passive_tray() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(1290, 846)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _slot_label("TrayTitle", "PASSIVES", 15, Color(1.0, 0.82, 0.3, 0.8), Vector2.ZERO, HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(0, 20)
	box.add_child(title)
	_passive_tray = HBoxContainer.new()
	_passive_tray.add_theme_constant_override("separation", 10)
	box.add_child(_passive_tray)
	game_ui.add_child(box)
	_refresh_passive_tray()


func _refresh_passive_tray() -> void:
	if not _passive_tray:
		return
	for c in _passive_tray.get_children():
		_passive_tray.remove_child(c)
		c.queue_free()
	for i in SpellSystem.PASSIVE_SLOTS:
		var slot := Panel.new()
		slot.custom_minimum_size = TRAY_SLOT
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.05, 0.04, 0.9)
		style.border_color = Color(1.0, 0.82, 0.3, 0.75 if i < SpellSystem.passives.size() else 0.25)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)
		if i < SpellSystem.passives.size():
			var spell: SpellData = SpellSystem.passives[i]
			slot.name = "P_" + spell.id
			slot.tooltip_text = "%s (passive)\n%s" % [spell.display_name, spell.description_plain()]
			var icon := TextureRect.new()
			icon.texture = spell_icon(spell)
			icon.modulate = Color(1.0, 0.85, 0.45)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_left = 8; icon.offset_top = 6; icon.offset_right = -8; icon.offset_bottom = -18
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)
			var name_lbl := _slot_label("Name", spell.display_name, 12, Color(1.0, 0.86, 0.55), Vector2(0, 64), HORIZONTAL_ALIGNMENT_CENTER)
			name_lbl.size = Vector2(TRAY_SLOT.x, 18)
			name_lbl.clip_text = true
			slot.add_child(name_lbl)
		else:
			slot.tooltip_text = "Empty passive slot — passives you pick go here."
		_passive_tray.add_child(slot)


## A passive just did something: its tray slot flashes gold.
func _pulse_passive(spell: SpellData) -> void:
	if not _passive_tray:
		return
	var slot := _passive_tray.get_node_or_null("P_" + spell.id)
	if not slot:
		return
	slot.pivot_offset = TRAY_SLOT / 2.0
	var tw := create_tween().set_parallel()
	slot.modulate = Color(1.8, 1.5, 0.7)
	slot.scale = Vector2.ONE * 1.12
	tw.tween_property(slot, "modulate", Color.WHITE, 0.45)
	tw.tween_property(slot, "scale", Vector2.ONE, 0.45)


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
	round_label.text = "Round %d" % GameManager.current_round
	timer_label.text = "Get ready"


func _on_contract_chosen(chosen: ContractData) -> void:
	current_contract = chosen
	party_choice_panel.visible = false
	await _clear_party_container()

	contract_name_label.text = chosen.contract_name.replace("  ", " ")
	contract_risk_label.text = "PARTY OF %d" % chosen.unit_templates.size()
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
	if GameManager.exhausted_time > 0.0 and GameManager.in_round:
		mana_label.text += "   EXHAUSTED %.0fs" % ceilf(GameManager.exhausted_time)
	var frac := GameManager.mana / maxf(1.0, GameManager.max_mana)
	var orb := clampi(int(ceil(frac * 4.0)), 1, 4)
	var tex = load(ART + "ui/bars/mana_orb_%d.png" % orb)
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


## A spell's icon, first match wins (owner, 2026-10-27: new art needs no code change):
##   1. ui/icons/spell_<id>.png (a rank can share its family's: spell_heal.png for Heal II)
##   2. the four hand-wired stand-ins (SPELL_ICONS)
##   3. ui/icons/tag_<tag>.png for the spell's main tag (passives: the tag they react to)
##   4. the old shared tag icons (TAG_ICONS), then the fallback
func spell_icon(spell: SpellData) -> Texture2D:
	for id in [spell.id, spell.family()]:
		var own := ART + "ui/icons/spell_%s.png" % id
		if ResourceLoader.exists(own):
			return load(own)
	var rel: String = SPELL_ICONS.get(spell.id, "")
	if rel == "":
		var look: Array = spell.tags + spell.reacts_to_tags
		for tag in TAG_ORDER:
			if look.has(tag):
				var tag_art := ART + "ui/icons/tag_%s.png" % tag.to_lower()
				if ResourceLoader.exists(tag_art):
					return load(tag_art)
				if TAG_ICONS.has(tag):
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

	btn.add_child(_slot_label("Key", key, 26, Color.WHITE, Vector2(6, 0), HORIZONTAL_ALIGNMENT_LEFT))
	if spell.is_passive():
		btn.add_child(_slot_label("Cost", "passive", 16, Color(1.0, 0.8, 0.35), Vector2(0, 84), HORIZONTAL_ALIGNMENT_CENTER))
	else:
		btn.add_child(_slot_label("Cost", str(int(spell.mana_cost)), 20, SpellTags.MANA_COLOR, Vector2(-6, 82), HORIZONTAL_ALIGNMENT_RIGHT))
		# Cast time on the button too (owner, 2026-10-24): "inst" or "1.5s", bottom left.
		var cast_txt := "inst" if spell.cast_time <= 0.0 else "%ss" % SpellData._num(spell.cast_time)
		var cast_lbl := _slot_label("Cast", cast_txt, 18, Color(0.93, 0.89, 0.8), Vector2(6, 84), HORIZONTAL_ALIGNMENT_LEFT)
		cast_lbl.add_theme_constant_override("outline_size", 5)
		cast_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_child(cast_lbl)
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
		_show_leaderboard(true, entries)
	else:
		submit_status.text = message
		submit_button.disabled = false
		name_edit.editable = true


# ── Leaderboard boards: ◀ older · newer ▶ ──────────────

var _board_nav: HBoxContainer

func _make_board_nav() -> void:
	var box := lb_grid.get_parent()
	_board_nav = HBoxContainer.new()
	_board_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	_board_nav.add_theme_constant_override("separation", 10)
	var older := Button.new()
	older.name = "Older"; older.text = "◀"; older.flat = true; older.focus_mode = Control.FOCUS_NONE
	older.tooltip_text = "Older leaderboard"
	older.pressed.connect(func(): _switch_board(1))
	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 20)
	title.custom_minimum_size = Vector2(220, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var newer := Button.new()
	newer.name = "Newer"; newer.text = "▶"; newer.flat = true; newer.focus_mode = Control.FOCUS_NONE
	newer.tooltip_text = "Newer leaderboard"
	newer.pressed.connect(func(): _switch_board(-1))
	_board_nav.add_child(older); _board_nav.add_child(title); _board_nav.add_child(newer)
	_board_nav.visible = false
	box.add_child(_board_nav)
	box.move_child(_board_nav, lb_grid.get_index())


func _switch_board(step: int) -> void:
	var id := Leaderboard.neighbour_board(step)
	if id != "":
		Leaderboard.fetch_top(id)


func _update_board_nav() -> void:
	if not _board_nav:
		return
	_board_nav.visible = Leaderboard.boards.size() > 1
	var current := Leaderboard.boards.any(func(b): return b.get("id") == Leaderboard.board_id and b.get("current", false))
	var title: Label = _board_nav.get_node("Title")
	title.text = Leaderboard.board_title + ("" if current else "  (old)")
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3) if current else Color(0.7, 0.66, 0.6))
	_board_nav.get_node("Older").disabled = Leaderboard.neighbour_board(1) == ""
	_board_nav.get_node("Newer").disabled = Leaderboard.neighbour_board(-1) == ""


func _show_leaderboard(ok: bool, entries: Array) -> void:
	_update_board_nav()
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
		if Leaderboard.board_kind == "classic":   # old boards: original score, then round reached
			_lb_cell(str(int(e.get("score", 0))), gold)
			_lb_cell("WON" if e.get("won", false) else "R%d" % int(e.get("round", 0)),
				Color(0.45, 0.9, 0.4) if e.get("won", false) else Color(0.6, 0.58, 0.55))
		else:
			_lb_cell("R%d" % int(e.get("rounds", 0)), gold)
			_lb_cell(RunStats.fmt(int(e.get("healing", 0))), Color(0.6, 0.58, 0.55))


func _lb_cell(text: String, color: Color, expand := false) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 24)
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
	lb_grid.add_child(l)


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
	cast_bar.visible = false
	fallen_name = ""
	round_label.modulate = Color.WHITE
	_set_pose("idle")
	await _clear_party_container()


func _on_play_again_pressed() -> void:
	game_over_panel.visible = false
	fallen_name = ""
	round_label.modulate = Color.WHITE
	_set_pose("idle")
	await _clear_party_container()
	GameManager.new_game()
