# ui/CardChoicePanel.gd
# A full-screen "pick one card" screen, used for the specialization pick and spell picks
# (and later keystones). It only draws cards from plain dictionaries and reports which
# one was chosen, so it knows nothing about spells.
#
# Card keys (all optional except title): header, header_color, icon, title, badge,
# badge_color, stats, tags (Array of SpellTags ids), body_bb, flavor, hint_bb, accent.
# Click a card or press 1/2/3 to choose.
extends Control

signal chosen(index: int)

const CARD_SIZE := Vector2(380, 560)
const BG := Color(0.07, 0.06, 0.06, 0.97)
const FRAME := Color(0.85, 0.8, 0.72, 0.9)

var _title: Label
var _subtitle: Label
var _row: HBoxContainer
var _cards: Array[Button] = []
var _styles: Array[StyleBoxFlat] = []
var _accents: Array[Color] = []
var _locked := false
var _tween: Tween
var _font_title: Font
var _font_flavor: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_font_title = load("res://assets/fonts/pirata-one-latin-400-normal.woff2")
	_font_flavor = load("res://assets/fonts/special-elite-latin-400-normal.woff2")

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.01, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_title:
		_title.add_theme_font_override("font", _font_title)
	_title.add_theme_font_size_override("font_size", 64)
	col.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 24)
	_subtitle.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	col.add_child(_subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	col.add_child(spacer)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 36)
	col.add_child(_row)


func show_cards(title: String, subtitle: String, cards: Array) -> void:
	if _tween:
		_tween.kill()   # a choice still fading out must not land on the new cards
	_title.text = title
	_subtitle.text = subtitle
	for c in _row.get_children():
		c.queue_free()
	_cards.clear()
	_styles.clear()
	_accents.clear()
	for i in cards.size():
		_row.add_child(_build_card(i, cards[i]))
	_locked = false
	visible = true
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.25)


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var i: int = event.keycode - KEY_1
	if i >= 0 and i < _cards.size():
		_choose(i)
		get_viewport().set_input_as_handled()


func _choose(i: int) -> void:
	if _locked:
		return
	_locked = true
	_set_hover(i, true)
	_tween = create_tween()
	_tween.tween_interval(0.15)
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_tween.tween_callback(func(): visible = false; chosen.emit(i))


# ── Card ───────────────────────────────────────────────

func _build_card(i: int, d: Dictionary) -> Button:
	var accent: Color = d.get("accent", FRAME)
	var btn := Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.border_color = accent.darkened(0.25)
	style.set_border_width_all(2)
	style.border_width_top = 8
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.5, 0.05, 0.05, 0.35)
	style.shadow_size = 14
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, style)
	btn.pressed.connect(_choose.bind(i))
	btn.mouse_entered.connect(_set_hover.bind(i, true))
	btn.mouse_exited.connect(_set_hover.bind(i, false))
	_cards.append(btn)
	_styles.append(style)
	_accents.append(accent)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24; box.offset_right = -24; box.offset_top = 22; box.offset_bottom = -18
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	head.add_child(_label(d.get("header", ""), 17, d.get("header_color", accent)))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(fill)
	if d.get("badge", "") != "":
		head.add_child(_chip(d.badge, d.get("badge_color", SpellTags.COMBO_COLOR), true))

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_row)
	if d.get("icon") is Texture2D:
		var icon := TextureRect.new()
		icon.texture = d.icon
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_row.add_child(icon)
	var t := _label(d.get("title", ""), 44, Color(0.96, 0.93, 0.86))
	if _font_title:
		t.add_theme_font_override("font", _font_title)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(t)

	if d.get("stats", "") != "":
		box.add_child(_label(d.stats, 18, Color(1.0, 0.8, 0.35)))

	var tags: Array = d.get("tags", [])
	if not tags.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 6)
		flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for tag in tags:
			flow.add_child(_chip(SpellTags.label(tag), SpellTags.COLORS.get(tag, Color.WHITE), false))
		box.add_child(flow)

	if d.get("body_bb", "") != "":
		box.add_child(_rich(d.body_bb, 21))

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grow)

	if d.get("hint_bb", "") != "":
		box.add_child(_rich(d.hint_bb, 19))
	if d.get("flavor", "") != "":
		var fl := _label("“%s”" % d.flavor, 16, Color(0.62, 0.58, 0.52))
		if _font_flavor:
			fl.add_theme_font_override("font", _font_flavor)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(fl)
	var key := _label("Press %d" % (i + 1), 15, Color(0.5, 0.48, 0.44))
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(key)
	return btn


func _set_hover(i: int, on: bool) -> void:
	if i >= _styles.size():
		return
	var s := _styles[i]
	s.border_color = _accents[i] if on else _accents[i].darkened(0.25)
	s.set_border_width_all(4 if on else 2)
	s.border_width_top = 8
	_cards[i].pivot_offset = CARD_SIZE / 2.0
	_cards[i].scale = Vector2.ONE * (1.03 if on else 1.0)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _rich(bb: String, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", Color(0.9, 0.87, 0.8))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _chip(text: String, color: Color, strong: bool) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color, 0.85 if strong else 0.18)
	s.border_color = color
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.content_margin_left = 8; s.content_margin_right = 8; s.content_margin_top = 2; s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := _label(text, 15, Color(0.08, 0.06, 0.05) if strong else color)
	l.add_theme_constant_override("outline_size", 0)
	p.add_child(l)
	return p
