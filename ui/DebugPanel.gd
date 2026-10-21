# ui/DebugPanel.gd
# Testing tools, toggled with F1 (or the ` key, since some browsers grab F1).
# Works in the web build too, so the owner can test on marz.gg — but any run where it
# changed something is marked debug_used and can't be posted to the online leaderboard.
extends CanvasLayer

const HIT_AMOUNT := 25.0
const MANA_AMOUNT := 50.0

var _panel: PanelContainer
var _info: Label
var _target_label: Label
var _round_spin: SpinBox
var _god_button: Button
var _target: Node = null


func _ready() -> void:
	layer = 50
	_build()
	_panel.visible = false
	EventBus.target_hovered.connect(func(t): if t != null: _target = t)
	EventBus.target_selected.connect(func(t): _target = t)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT):
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var r := GameManager.current_round
	var bursts := []
	if DifficultySystem.has_method("get_burst_damage"):
		for armor in ["LIGHT", "MEDIUM", "HEAVY"]:
			bursts.append("%s %d" % [armor.substr(0, 1), roundi(DifficultySystem.get_burst_damage(r, armor, false))])
	else:
		bursts.append("n/a")
	_info.text = "Round %d · %s · %.1fs left\nMana %d / %d · regen %.1f/s\nDamage %.1f/s base · bursts %s\nBaron round: %s · %s" % [
		r, "in round" if GameManager.in_round else "between rounds", GameManager.round_time,
		GameManager.mana, GameManager.max_mana, GameManager.regen_rate,
		DifficultySystem.get_base_dps(r), " / ".join(bursts),
		"yes" if DifficultySystem.is_boss_round(r) else "no",
		"DEBUG RUN — can't be posted" if GameManager.debug_used else "clean run"]
	var valid := is_instance_valid(_target)
	_target_label.text = "Fighter: %s" % (_target.display_name if valid else "hover or click one")


# ── Actions ────────────────────────────────────────────

func _add_mana() -> void:
	GameManager.debug_add_mana(MANA_AMOUNT)


func _skip_round() -> void:
	GameManager.debug_skip_round()


func _jump() -> void:
	GameManager.debug_jump_to_round(int(_round_spin.value))


func _hit_target() -> void:
	if not is_instance_valid(_target) or not GameManager.in_round:
		return
	GameManager.debug_used = true
	_target.health_comp.take_damage(HIT_AMOUNT)


func _heal_target() -> void:
	if not is_instance_valid(_target):
		return
	GameManager.debug_used = true
	_target.health_comp.heal(_target.health_comp.max_health)


func _toggle_god() -> void:
	GameManager.god_mode = not GameManager.god_mode
	if GameManager.god_mode:
		GameManager.debug_used = true
	for t in TargetSystem.targets:
		if is_instance_valid(t):
			t.health_comp.invulnerable = GameManager.god_mode
	_god_button.text = "God mode: %s" % ("ON" if GameManager.god_mode else "off")


# ── Layout ─────────────────────────────────────────────

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 120)
	_panel.custom_minimum_size = Vector2(380, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "DEBUG  (F1 / ` to close)"
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	box.add_child(title)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 15)
	box.add_child(_info)

	_add_button(box, "+%d mana" % MANA_AMOUNT, _add_mana)
	_add_button(box, "Skip round (counts as survived)", _skip_round)

	var jump := HBoxContainer.new()
	box.add_child(jump)
	var jl := Label.new(); jl.text = "Jump to round"
	jump.add_child(jl)
	_round_spin = SpinBox.new()
	_round_spin.min_value = 1; _round_spin.max_value = 999; _round_spin.value = 5
	jump.add_child(_round_spin)
	_add_button(jump, "Go", _jump)

	_target_label = Label.new()
	box.add_child(_target_label)
	var fighter := HBoxContainer.new()
	box.add_child(fighter)
	_add_button(fighter, "Hit %d" % HIT_AMOUNT, _hit_target)
	_add_button(fighter, "Heal to full", _heal_target)

	_god_button = _add_button(box, "God mode: off", _toggle_god)

	var note := Label.new()
	note.text = "Using these marks the run as a debug run:\nit won't post to the leaderboard or high score."
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	box.add_child(note)


func _add_button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # keep Q/W/E/R/T working for spells
	b.pressed.connect(action)
	parent.add_child(b)
	return b
