# ui/PauseMenu.gd
# Escape during a run: pauses the game and offers Resume / Restart run / Quit to title.
# It only reports the choice through signals; game.gd decides what restarting or quitting means.
extends Control

signal restart_requested
signal quit_requested

const QUIPS := [
	"Take a breath. They can't bleed while you're not looking. Probably.",
	"The wounded will wait. Briefly.",
	"Even healers get a smoke break.",
]

## Set by game.gd: whether Escape should open the menu right now (only during a run).
var can_open: Callable = func(): return true

var _quip: Label
var _resume: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps working while the game is paused
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	visible = false

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.01, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.06, 0.97)
	style.border_color = Color(0.85, 0.8, 0.72, 0.9)
	style.set_border_width_all(2)
	style.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size = Vector2(460, 0)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/pirata-one-latin-400-normal.woff2"))
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.85, 0.2, 0.18))
	col.add_child(title)

	_quip = Label.new()
	_quip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quip.add_theme_font_override("font", load("res://assets/fonts/special-elite-latin-400-normal.woff2"))
	_quip.add_theme_font_size_override("font_size", 20)
	_quip.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	col.add_child(_quip)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	col.add_child(gap)

	_resume = _button(col, "Resume  (Esc)", close)
	_button(col, "Restart run", func(): close(); restart_requested.emit())
	_button(col, "Quit to title", func(): close(); quit_requested.emit())

	# Sound (Phase G, #33): volume and mute, saved on this device.
	var sound := HBoxContainer.new()
	sound.add_theme_constant_override("separation", 14)
	col.add_child(sound)
	var lbl := Label.new()
	lbl.text = "Sound"
	lbl.add_theme_font_size_override("font_size", 22)
	sound.add_child(lbl)
	var slider := HSlider.new()
	slider.name = "Volume"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SoundSystem.volume
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(SoundSystem.set_volume)
	sound.add_child(slider)
	var mute := CheckBox.new()
	mute.name = "Mute"
	mute.text = "Mute"
	mute.button_pressed = SoundSystem.muted
	mute.add_theme_font_size_override("font_size", 20)
	mute.toggled.connect(SoundSystem.set_muted)
	sound.add_child(mute)

	# Steam polish: comfort and accessibility. Turns off screen shake and the combo punch.
	var calm := CheckBox.new()
	calm.name = "ReduceEffects"
	calm.text = "Reduce screen shake and flashes"
	calm.button_pressed = ScreenFeel.reduce_effects
	calm.add_theme_font_size_override("font_size", 20)
	calm.toggled.connect(ScreenFeel.set_reduce)
	col.add_child(calm)

	var note := Label.new()
	note.text = "Restarting or quitting ends this run. It isn't posted to the leaderboard."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", Palette.MIN_FONT)
	note.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
	col.add_child(note)


func _buttons_for_test() -> Array:
	return [_resume] + _resume.get_parent().get_children().filter(func(c): return c is Button and c != _resume)


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if visible:
			close()
		elif can_open.call():
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_quip.text = QUIPS.pick_random()
	visible = true
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
