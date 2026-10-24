# scenes/practice.gd
# The first-time practice round (owner, 2026-10-24). The first time someone presses
# Take the Job on this device, the game asks "First time on the job?". Yes → this round:
# one Heavy Knight, Heal only, a few short prompts, then the real run starts. The knight
# can't die and nothing here counts toward stats or the leaderboard. The question is asked
# once per device, whatever the answer.
class_name PracticeRound
extends Node

signal finished

## Where "already asked" is remembered. Tests point this somewhere else.
static var settings_path := "user://settings.cfg"

## The knight's health when practice starts (fraction of max), and the warned hit.
@export var start_health := 0.45
@export var burst_damage := 35.0
@export var burst_warning := 4.0
## How long the "mana and cast time" prompt stays up before the warned hit.
@export var mana_step_time := 6.0

var game: Node
var knight: Node
var step := -1
var _wait := 0.0
var _saved_burst_interval := 0.0
var _banner: PanelContainer
var _text: RichTextLabel
var _button: Button


static func was_asked() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(settings_path) == OK and cfg.get_value("onboarding", "asked_first_time", false)


static func mark_asked() -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path)   # keep anything else saved there
	cfg.set_value("onboarding", "asked_first_time", true)
	cfg.save(settings_path)


func _init(game_scene: Node) -> void:
	game = game_scene
	name = "PracticeRound"


func begin() -> void:
	_saved_burst_interval = DifficultySystem.burst_interval
	DifficultySystem.burst_interval = 1.0e9   # no random hits: the prompts schedule the one hit
	GameManager.start_practice()
	SpellSystem.set_spellbook_ids(PackedStringArray(["heal"]))
	var contract := ContractData.new()
	contract.contract_name = "Practice"
	var u := UnitTemplate.new()
	u.display_name = "Heavy Knight"
	u.character = "knight"
	u.armor_type = "HEAVY"
	u.base_max_health = ContractGenerator.armor_base_hp.get("HEAVY", 100)
	contract.unit_templates = [u]
	await game._on_contract_chosen(contract)
	if not is_inside_tree() or TargetSystem.targets.is_empty():
		return
	knight = TargetSystem.targets[0]
	knight.health_comp.invulnerable = true   # practice: he can drop to 1, never die
	knight.health_comp.current_health = knight.health_comp.max_health * start_health
	game.round_label.text = "Practice"
	game.contract_risk_label.text = "ONE FIGHTER"
	game._say("practice_start", 5.0)
	_make_banner()
	EventBus.healed.connect(_on_healed)
	_go(0)


func _make_banner() -> void:
	_banner = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.04, 0.92)
	style.border_color = Color(0.85, 0.82, 0.76)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(20)
	_banner.add_theme_stylebox_override("panel", style)
	# Right of the knight, clear of his INCOMING warning and health bar.
	_banner.position = Vector2(1170, 300)
	_banner.custom_minimum_size = Vector2(600, 0)
	_banner.size = Vector2(600, 0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(box)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(560, 0)
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 28)
	_text.add_theme_font_size_override("bold_font_size", 28)
	box.add_child(_text)
	_button = Button.new()
	_button.text = "Start the real job  (Enter)"
	_button.custom_minimum_size = Vector2(380, 64)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 28)
	_button.visible = false
	_button.pressed.connect(finish)
	box.add_child(_button)
	game.game_ui.add_child(_banner)


## The prompts, in order. Tags use the game's colours (green = healing, red = danger).
func _go(n: int) -> void:
	step = n
	_wait = 0.0
	var green := Color(0.49, 0.95, 0.35).to_html(false)
	var red := Color(1.0, 0.35, 0.3).to_html(false)
	match n:
		0:
			_text.text = "[center]The knight is hurt. Point at him and press [b]Q[/b] to cast [color=#%s][b]Heal[/b][/color].\n[font_size=22](Or click the Heal button, then click him.)[/font_size][/center]" % green
		1:
			_text.text = "[center]Heal takes [b]1.5s[/b] to cast: the bar under the spells fills while you cast.\nEvery spell costs [b]mana[/b] (the big bar). It refills slowly, so don't waste it.[/center]"
			_wait = mana_step_time
		2:
			var to_half: float = knight.health_comp.current_health - knight.health_comp.max_health * 0.5
			if to_half > 0.0:
				knight.health_comp.take_damage(to_half)   # knock him to half so the hit matters
			TargetSystem.telegraph(knight, burst_damage, burst_warning, "INCOMING")
			_text.text = "[center]A [color=#%s][b]red ring and INCOMING[/b][/color] means a big hit is coming.\nHeal him up before it lands.[/center]" % red
		3:
			_text.text = "[center]That's the job: keep [b]everyone[/b] alive.\nIn a real run the party grows, the hits get bigger, and you pick new spells as you go.\n[color=#%s][b]If anyone dies, the run is over.[/b][/color][/center]" % red
			_button.visible = true
			game._say("practice_done", 6.0)


func _on_healed(target: Node, _amount: float, _overheal: float, spell: SpellData, _tags: Array) -> void:
	if step == 0 and target == knight and spell != null:
		_go(1)


func _process(delta: float) -> void:
	if step < 0 or not is_instance_valid(knight):
		return
	match step:
		1:
			_wait -= delta
			if _wait <= 0.0:
				_go(2)
		2:
			if knight.pending_burst_time <= 0.0 and TargetSystem.pending_bursts.is_empty():
				_wait += delta
				if _wait >= 1.0:   # a beat after the hit lands
					_go(3)


func _unhandled_input(event: InputEvent) -> void:
	if step == 3 and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		finish()


## Practice is over: clear it away and start the real run (spell choice).
func finish() -> void:
	if step < 0:
		return
	_cleanup()
	finished.emit()


## Leaves without starting a run (pause menu → Quit to title / Restart).
func cancel() -> void:
	_cleanup()


func _cleanup() -> void:
	step = -1
	if EventBus.healed.is_connected(_on_healed):
		EventBus.healed.disconnect(_on_healed)
	DifficultySystem.burst_interval = _saved_burst_interval
	GameManager.end_practice()
	if _banner:
		_banner.queue_free()
		_banner = null
	queue_free()
