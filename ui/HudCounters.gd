# ui/HudCounters.gd
# The small always-on HUD pieces: battlefield rules (top right), the passive tray, and the
# Cleanse (F) and bandage (Space) counters. Each builds itself and listens to its system.
# Created by scenes/game.gd inside GameUI; positions are on the 1920x1080 screen.
class_name HudCounters
extends Control

const VIOLET_HEX := "b873ff"
const TRAY_SLOT := Vector2(84, 84)

var rules_box: VBoxContainer
var passive_tray: HBoxContainer
var _tray_box: VBoxContainer
var bandage_label: RichTextLabel
var cleanse_label: RichTextLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_passive_tray()
	_make_bandage_counter()
	_make_cleanse_counter()
	_make_rules_panel()
	SpellSystem.spellbook_changed.connect(_refresh_rules_panel)
	SpellSystem.spellbook_changed.connect(_refresh_passive_tray)
	SpellSystem.spellbook_changed.connect(_update_cleanse)
	EventBus.passive_triggered.connect(_pulse_passive)
	BandageSystem.charges_changed.connect(func(_c, _m): _update_bandages())
	BandageSystem.bandage_failed.connect(func(reason): if reason == "no_charges": _flash_red(bandage_label))
	CleanseSystem.charges_changed.connect(func(_c, _m): _update_cleanse())
	CleanseSystem.cleanse_failed.connect(func(reason): if reason == "no_charges": _flash_red(cleanse_label))


## Called by game.gd once everything exists: rules stay top right, the rest stays by the spell bar.
func pin_layout() -> void:
	var L := ScreenLayout
	L.pin(rules_box, L.RIGHT, L.TOP)
	for n in [_tray_box, bandage_label, cleanse_label]:
		L.pin(n, L.CENTER, L.BOTTOM)


func _process(_delta: float) -> void:
	_pulse_cleanse()


## A small fixed label (tray and rules titles; the spell bar uses it too).
static func make_label(n: String, text: String, size: int, color: Color, offset: Vector2, align: HorizontalAlignment) -> Label:
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


func _rich_label(pos: Vector2, width: float) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_theme_font_size_override("normal_font_size", 20)
	l.add_theme_font_size_override("bold_font_size", 20)
	l.position = pos
	l.size = Vector2(width, 34)
	add_child(l)
	return l


func _flash_red(node: CanvasItem) -> void:
	var tw := create_tween()
	node.modulate = Color(1.0, 0.3, 0.3)
	tw.tween_property(node, "modulate", Color.WHITE, 0.4)


# ── Battlefield rules: always on screen, top right ─────

func _make_rules_panel() -> void:
	rules_box = VBoxContainer.new()
	rules_box.position = Vector2(1530, 28)
	rules_box.custom_minimum_size = Vector2(370, 0)
	rules_box.add_theme_constant_override("separation", 2)
	add_child(rules_box)
	_refresh_rules_panel()


func _refresh_rules_panel() -> void:
	if not rules_box:
		return
	for c in rules_box.get_children():
		rules_box.remove_child(c)
		c.queue_free()
	var title := make_label("RulesTitle", "BATTLEFIELD RULES", Palette.MIN_FONT, Palette.DANGER, Vector2.ZERO, HORIZONTAL_ALIGNMENT_RIGHT)
	title.custom_minimum_size = Vector2(370, 26)
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.tooltip_text = "Rules everyone plays by. Some passives cancel a rule (shown in gold)."
	rules_box.add_child(title)
	for rule in EffectSystem.battlefield_rules:
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.custom_minimum_size = Vector2(370, 0)
		line.add_theme_font_size_override("normal_font_size", 20)
		line.add_theme_font_size_override("bold_font_size", 20)
		var by := EffectSystem.cancelled_by(rule.rule_id)
		if by:
			line.text = "[right][color=#6f6a63][s]%s[/s][/color]  [color=#ffd24d]→ %s[/color][/right]" % [rule.rule_name, by.display_name]
			line.tooltip_text = "%s is cancelled by your %s:\n%s" % [rule.rule_name, by.display_name, by.description_plain()]
		else:
			line.text = "[right][color=#d9d2c5]%s[/color][/right]" % rule.rule_name
			line.tooltip_text = "%s: %s" % [rule.rule_name, SpellTags.fill_plain(rule.describe())]
		rules_box.add_child(line)


# ── Bandages: counter right of the passive tray (Space) ──────────

func _make_bandage_counter() -> void:
	bandage_label = _rich_label(Vector2(1600, 922), 300)   # beside the passive tray
	bandage_label.tooltip_text = "Bandages: hover a fighter and press Space to channel %d healing over %ss.\nYou can't cast while bandaging. +1 bandage every %d rounds (max %d)." % [
		int(BandageSystem.heal_total), str(BandageSystem.channel_time), BandageSystem.gain_every_rounds, BandageSystem.max_charges]
	_update_bandages()


func _update_bandages() -> void:
	var full := "■".repeat(BandageSystem.charges)
	var empty := "□".repeat(maxi(0, BandageSystem.max_charges - BandageSystem.charges))
	bandage_label.text = "[b]BANDAGES[/b]  [color=#7df25a]%s[/color][color=#5a554e]%s[/color]  [color=#a9a39a]Space[/color]" % [full, empty]


# ── Cleanse (Phase F): counter above the bandages (F) ──

func _make_cleanse_counter() -> void:
	cleanse_label = _rich_label(Vector2(1600, 882), 320)
	_update_cleanse()


func _update_cleanse() -> void:
	var sp := CleanseSystem.spell()
	if not sp:
		cleanse_label.text = ""
		return
	var full := "◆".repeat(CleanseSystem.charges)
	var empty := "◇".repeat(maxi(0, CleanseSystem.max_charges() - CleanseSystem.charges))
	cleanse_label.text = "[b]%s[/b]  [color=#%s]%s[/color][color=#5a554e]%s[/color]  [color=#a9a39a]F[/color]" % [
		sp.display_name.to_upper(), VIOLET_HEX, full, empty]
	cleanse_label.tooltip_text = "%s: point at a fighter and press F. %s\nFree and instant; charges come back during the round (one every %ss)." % [
		sp.display_name, sp.description_plain(), str(sp.charge_time)]


## The counter glows violet when F on the hovered fighter would remove something.
func _pulse_cleanse() -> void:
	if not cleanse_label:
		return
	var helps := GameManager.in_round and CleanseSystem.would_help(SpellSystem.hovered_target)
	var t := Time.get_ticks_msec() / 1000.0
	cleanse_label.modulate = Color(1.25 + 0.35 * sin(t * 8.0), 0.95, 1.45) if helps else Color.WHITE


# ── Passive tray: 3 gold slots next to the spell bar ───

func _make_passive_tray() -> void:
	var box := VBoxContainer.new()
	_tray_box = box
	box.position = Vector2(1290, 840)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := make_label("TrayTitle", "PASSIVES", Palette.MIN_FONT, Palette.COMBO, Vector2.ZERO, HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(0, 24)
	box.add_child(title)
	passive_tray = HBoxContainer.new()
	passive_tray.add_theme_constant_override("separation", 10)
	box.add_child(passive_tray)
	add_child(box)
	_refresh_passive_tray()


func _refresh_passive_tray() -> void:
	if not passive_tray:
		return
	for c in passive_tray.get_children():
		passive_tray.remove_child(c)
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
			icon.texture = PickCards.spell_icon(spell)
			icon.modulate = Color(1.0, 0.85, 0.45)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_left = 6; icon.offset_top = 6; icon.offset_right = -6; icon.offset_bottom = -6
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)
			# Name under the slot (was 12 px inside it); the full name is in the tooltip.
			var name_lbl := make_label("Name", spell.display_name, Palette.MIN_FONT, Palette.COMBO, Vector2(-4, TRAY_SLOT.y + 2), HORIZONTAL_ALIGNMENT_CENTER)
			name_lbl.size = Vector2(TRAY_SLOT.x + 8, 26)
			name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			slot.add_child(name_lbl)
		else:
			slot.tooltip_text = "Empty passive slot — passives you pick go here."
		passive_tray.add_child(slot)


## A passive just did something: its tray slot flashes gold.
func _pulse_passive(spell: SpellData) -> void:
	if not passive_tray:
		return
	var slot := passive_tray.get_node_or_null("P_" + spell.id)
	if not slot:
		return
	slot.pivot_offset = TRAY_SLOT / 2.0
	var tw := create_tween().set_parallel()
	slot.modulate = Color(1.8, 1.5, 0.7)
	slot.scale = Vector2.ONE * 1.12
	tw.tween_property(slot, "modulate", Color.WHITE, 0.45)
	tw.tween_property(slot, "scale", Vector2.ONE, 0.45)
