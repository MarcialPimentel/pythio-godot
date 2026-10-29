# entities/Target.gd — one fighter on the battlefield: art, health bar, status, effects.
# Art is loaded by file name from assets/art (see docs/art.md), so swapping in
# high-res images needs no code change.
extends Control

@export var armor_type: String = "LIGHT"          # LIGHT / MEDIUM / HEAVY (from UnitTemplate)
@export var character: String = "adventurer"      # which art to show
@export var display_name: String = "Fighter"
@export var max_hp: float = 100.0
@export var index: int = 0
@export var pending_burst_time: float = 0.0

## Sprite height in pixels (bosses use boss_sprite_height).
@export var sprite_height: float = 280.0
@export var boss_sprite_height: float = 340.0

const ART_DIR := "res://assets/art/"
const FLOAT_HEAL := Palette.HEAL
const FLOAT_SHIELD := Palette.SHIELD
const FLOAT_DANGER := Palette.DANGER
const FLOAT_COMBO := Palette.COMBO   # gold = combos

@onready var health_comp: HealthComponent = $HealthComponent
@onready var sprite: TextureRect = $Sprite
@onready var telegraph: TextureRect = $Telegraph
@onready var hot_ring: TextureRect = $HotRing
@onready var shield_bubble: TextureRect = $ShieldBubble
@onready var status_icons: HBoxContainer = $StatusIcons
@onready var incoming_label: Label = $IncomingLabel
@onready var target_name: Label = $NameLabel
@onready var hp_bar: TextureProgressBar = $HealthBar
@onready var shield_bar: TextureProgressBar = $ShieldBar
@onready var hp_label: Label = $HPLabel
@onready var info_label: Label = $InfoLabel
@onready var fx_layer: Control = $FX
@onready var target_button: Button = $TargetButton

signal target_pressed(target: Node)

var is_boss := false
var hovered := false
var _feet_y := 330.0
var _icon_hot: TextureRect
var _icon_shield: TextureRect
var _icon_danger: TextureRect
var _icon_protect: TextureRect
var _icon_delayed: TextureRect
var _icon_saturated: TextureRect
## Phase F: debuff warnings above the fighter (like "! INCOMING") and Dread's line on the bar.
var _debuff_label: RichTextLabel
var _dread_line: ColorRect


func _ready() -> void:
	is_boss = get_meta("is_boss_unit", false)
	_setup_sprite()
	_setup_status_icons()
	# Glowing (additive) effects read better on the dark background
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	shield_bubble.material = add
	hot_ring.material = add
	target_name.text = display_name
	info_label.text = ("BOSS · " if is_boss else "") + "%s ARMOR" % armor_type

	target_button.pressed.connect(_on_target_button_pressed)
	# Hover-to-cast: tell the spell system which fighter is under the mouse
	target_button.mouse_entered.connect(func(): hovered = true; EventBus.target_hovered.emit(self))
	target_button.mouse_exited.connect(func(): hovered = false; EventBus.target_hovered.emit(null))

	health_comp.health_changed.connect(func(_h): _refresh_bars())
	health_comp.shield_changed.connect(func(_s): _refresh_bars())
	health_comp.died.connect(_on_died)
	EffectSystem.effect_applied.connect(_on_effect_applied)
	EventBus.burst_warned.connect(_on_burst_warned)
	EventBus.burst_landed.connect(_on_burst_landed)
	EventBus.combo_fired.connect(_on_combo_fired)
	EventBus.rule_triggered.connect(_on_rule_triggered)
	_setup_debuff_ui()
	EventBus.debuff_applied.connect(_on_debuff_applied)
	EventBus.cleansed.connect(func(t, count, _sp): if t == self and count > 0: _float_text("Cleansed", DebuffStatus.VIOLET, 0.85))
	EventBus.dread_struck.connect(func(t): if t == self: _float_text("DREAD", DebuffStatus.VIOLET, 1.3, 40.0))

	hp_bar.max_value = health_comp.max_health
	shield_bar.max_value = health_comp.max_health
	_refresh_bars()


func _setup_sprite() -> void:
	var tex := _load_art("characters/%s/%s_1.png" % [character, character])
	if tex:
		sprite.texture = tex
	var h := boss_sprite_height if is_boss else sprite_height
	var aspect := sprite.texture.get_width() / float(sprite.texture.get_height()) if sprite.texture else 0.7
	var w := h * aspect
	sprite.position = Vector2((size.x - w) / 2.0, _feet_y - h)
	sprite.size = Vector2(w, h)
	sprite.pivot_offset = Vector2(w / 2.0, h)
	# Shield bubble wraps the sprite
	shield_bubble.size = Vector2(maxf(w, h * 0.75) * 1.15, h * 1.08)
	shield_bubble.position = Vector2((size.x - shield_bubble.size.x) / 2.0, _feet_y - shield_bubble.size.y + 10)
	if is_boss:
		status_icons.position.y = _feet_y - h - 80   # icons above the warning text
		incoming_label.position.y = _feet_y - h - 40


func _setup_debuff_ui() -> void:
	_debuff_label = RichTextLabel.new()
	_debuff_label.bbcode_enabled = true
	_debuff_label.scroll_active = false
	_debuff_label.fit_content = true
	_debuff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debuff_label.add_theme_font_override("normal_font", incoming_label.get_theme_font("font"))
	_debuff_label.add_theme_font_size_override("normal_font_size", 22)
	_debuff_label.add_theme_constant_override("outline_size", 6)
	_debuff_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debuff_label.position = Vector2(-20, incoming_label.position.y - 30)   # just above "! INCOMING"
	_debuff_label.size = Vector2(size.x + 40, 30)
	add_child(_debuff_label)
	_dread_line = ColorRect.new()
	_dread_line.color = DebuffStatus.VIOLET
	_dread_line.size = Vector2(4, 30)
	_dread_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dread_line.visible = false
	add_child(_dread_line)


## Where `health` sits on the health bar, in this fighter's coordinates (x).
func _bar_x(health: float) -> float:
	var tex := hp_bar.texture_progress
	var fill_w: float = tex.get_width() if tex else 300.0
	var frac := clampf(health / maxf(1.0, health_comp.max_health), 0.0, 1.0)
	return hp_bar.position.x + (hp_bar.texture_progress_offset.x + fill_w * frac) * hp_bar.scale.x


func _on_debuff_applied(t: Node, status) -> void:
	if t != self:
		return
	var words := {"POISON": "Poisoned", "BLEED": "Bleeding", "HEX": "Hexed", "DREAD": "Dread"}
	_float_text(words.get(status.debuff, status.debuff.capitalize()), status.color(), 0.9, 30.0)


## The line under the health bar: heal-over-time timers (green) or the armour (default).
## Only touches the label when something changed (this runs every frame for every fighter).
var _info_is_hot := false
func _set_info(text: String, hot: bool) -> void:
	if info_label.text != text:
		info_label.text = text
	if hot != _info_is_hot:
		_info_is_hot = hot
		if hot:
			info_label.add_theme_color_override("font_color", FLOAT_HEAL)
		else:
			info_label.remove_theme_color_override("font_color")


func _update_debuff_ui() -> void:
	var list: Array = health_comp.debuffs() if not health_comp.is_dead else []
	var parts: Array[String] = []
	for d in list:
		parts.append("[color=#%s]%s[/color]" % [d.color().to_html(false), d.warning_text()])
	var text := "[center]%s[/center]" % "   ".join(parts) if not parts.is_empty() else ""
	if _debuff_label.text != text:   # only re-read the BBCode when it changed
		_debuff_label.text = text
	var dread := health_comp.get_debuff("DREAD") if not health_comp.is_dead else null
	_dread_line.visible = dread != null
	if dread:
		var tex := hp_bar.texture_progress
		var h: float = (tex.get_height() if tex else 20.0) * hp_bar.scale.y
		_dread_line.size = Vector2(4, h + 8)
		_dread_line.position = Vector2(_bar_x(dread.threshold) - 2, hp_bar.position.y + hp_bar.texture_progress_offset.y * hp_bar.scale.y - 4)


func _setup_status_icons() -> void:
	_icon_hot = _make_status_icon("ui/icons/status_buff_1.png")
	_icon_shield = _make_status_icon("ui/icons/status_buff_3.png")
	_icon_danger = _make_status_icon("ui/icons/status_debuff_1.png")
	_icon_protect = _make_status_icon("ui/icons/status_buff_4.png")
	_icon_delayed = _make_status_icon("ui/icons/status_buff_2.png")
	_icon_saturated = _make_status_icon("ui/icons/status_debuff_2.png")


func _make_status_icon(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _load_art(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(28, 36)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.visible = false
	status_icons.add_child(t)
	return t


func _load_art(rel: String) -> Texture2D:
	var path := ART_DIR + rel
	return load(path) if ResourceLoader.exists(path) else null


func _refresh_bars() -> void:
	if not health_comp:
		return
	hp_bar.value = health_comp.current_health
	shield_bar.value = health_comp.shield_amount
	shield_bar.visible = health_comp.shield_amount > 0.0
	var txt := "%d / %d" % [ceili(health_comp.current_health), int(health_comp.max_health)]
	if health_comp.shield_amount > 0.0:
		txt += "  +%d" % int(health_comp.shield_amount)
	hp_label.text = txt


func _on_target_button_pressed() -> void:
	EventBus.target_selected.emit(self)


func _on_died() -> void:
	pending_burst_time = 0.0
	var down := _load_art("characters/%s/%s_down.png" % [character, character])
	if down:
		sprite.texture = down
		var w := sprite_height * 0.9
		var h := w * down.get_height() / float(down.get_width())
		sprite.size = Vector2(w, h)
		sprite.position = Vector2((size.x - w) / 2.0, _feet_y - h)
	info_label.text = "FALLEN"
	info_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.2))
	_spawn_fx("vfx/danger/blood_burst_3.png", Vector2(size.x / 2.0, _feet_y - 60), 1.2, Color.WHITE)


func _on_effect_applied(effect_type: String, target, value: float, _vfx_color: String) -> void:
	if target != self:
		return
	match effect_type:
		"heal":
			_float_text("+%d" % int(value), FLOAT_HEAL)
			_spawn_fx("vfx/heal/heal_burst_4.png", Vector2(size.x / 2.0, _feet_y - sprite.size.y * 0.55), 0.6, Color.WHITE)
		"shield":
			_float_text("+%d shield" % int(value), FLOAT_SHIELD)
			_spawn_fx("vfx/shield/shield_impact_2.png", Vector2(size.x / 2.0, _feet_y - sprite.size.y * 0.5), 0.5, Color.WHITE)
		"hot":
			_float_text("+%d over time" % int(value), FLOAT_HEAL)
		"hot_tick":
			_float_text("+%d" % int(value), FLOAT_HEAL, 0.7)
		"protect":
			_float_text("Protected", FLOAT_SHIELD)
			_spawn_fx("vfx/shield/shield_impact_2.png", Vector2(size.x / 2.0, _feet_y - sprite.size.y * 0.5), 0.5, Color.WHITE)
		"delayed":
			if value > 0.0:
				_float_text("Blooms soon", FLOAT_HEAL, 0.8)


## A battlefield rule bit this fighter: a muted grey word so you learn why.
func _on_rule_triggered(kind: String, target) -> void:
	if target != self:
		return
	match kind:
		"diminished": _float_text("Diminished", Color(0.62, 0.66, 0.75), 0.75, 30.0)
		"saturated": _float_text("Saturated", Color(0.72, 0.68, 0.62), 0.75, 30.0)


## A synergy fired on this fighter: gold flash, gold burst and the combo's name.
func _on_combo_fired(target, label: String) -> void:
	if target != self:
		return
	_float_text(label, FLOAT_COMBO, 1.15, 56.0)   # above the heal numbers
	_spawn_fx("vfx/heal/heal_burst_6.png", Vector2(size.x / 2.0, _feet_y - sprite.size.y * 0.55), 0.7, FLOAT_COMBO)
	var tw := create_tween()
	sprite.self_modulate = Color(1.8, 1.5, 0.7)
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.5)


func _on_burst_warned(target, damage: float, _delay: float, label: String) -> void:
	if target != self:
		return
	incoming_label.text = "! %s %d" % [label, roundi(damage)]


func _on_burst_landed(target, absorbed: float, dealt: float) -> void:
	if target != self:
		return
	var mid := Vector2(size.x / 2.0, _feet_y - sprite.size.y * 0.5)
	if absorbed > 0.0:
		_float_text("Absorbed %d" % roundi(absorbed), FLOAT_SHIELD)
		_spawn_fx("vfx/shield/shield_impact_2.png", mid, 0.5, Color.WHITE)
	if dealt > 0.0:
		_float_text("-%d" % roundi(dealt), FLOAT_DANGER)
		_spawn_fx("vfx/danger/blood_burst_1.png", mid, 0.6, Color.WHITE)


func _float_text(text: String, color: Color, scale_factor: float = 1.0, lift: float = 0.0) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", int(34 * scale_factor))
	l.position = Vector2(size.x * 0.5 + randf_range(-30, 30), _feet_y - sprite.size.y - 10 - lift)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(l)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 70, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


func _spawn_fx(rel: String, center: Vector2, duration: float, tint: Color) -> void:
	var tex := _load_art(rel)
	if not tex:
		return
	var t := TextureRect.new()
	t.texture = tex
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = tint
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	t.material = add
	t.size = tex.get_size() * 1.6
	t.pivot_offset = t.size / 2.0
	t.position = center - t.size / 2.0
	t.scale = Vector2(0.4, 0.4)
	fx_layer.add_child(t)
	var tw := create_tween().set_parallel()
	tw.tween_property(t, "scale", Vector2(1.15, 1.15), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(t, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.4)
	tw.chain().tween_callback(t.queue_free)


func _process(delta: float) -> void:
	var dead := health_comp and health_comp.is_dead
	var t := Time.get_ticks_msec() / 1000.0

	# Burst telegraph: red ring under the feet + pulsing red tint
	var bursting := pending_burst_time > 0.0 and not dead
	if pending_burst_time > 0.0:
		pending_burst_time -= delta
	telegraph.visible = bursting
	incoming_label.visible = bursting
	_icon_danger.visible = bursting
	if bursting:
		var pulse := sin(t * 10.0) * 0.5 + 0.5
		telegraph.scale = Vector2.ONE * (0.9 + 0.15 * pulse)
		telegraph.pivot_offset = telegraph.size / 2.0

	_update_debuff_ui()

	# Buff visuals
	var has_hot := health_comp.hot_time > 0.0 and not dead
	var has_shield := health_comp.shield_amount > 0.0 and not dead
	hot_ring.visible = has_hot
	_icon_hot.visible = has_hot
	shield_bubble.visible = has_shield
	_icon_shield.visible = has_shield
	if has_shield:
		shield_bubble.modulate.a = 0.75 + 0.2 * sin(t * 3.0)
	_icon_protect.visible = not dead and (health_comp.has_status("PROTECT") or health_comp.has_status("SAVE"))
	_icon_delayed.visible = not dead and (health_comp.has_status("DELAYED") or health_comp.has_status("ECHO"))
	_icon_saturated.visible = not dead and health_comp.has_status("SATURATED")
	if has_hot:
		# Every heal-over-time gets its own line (owner, 2026-10-24: with only the longest one
		# shown, Renew + Healing Plague looked like they didn't stack; they do, and both heal).
		var hots := health_comp.get_statuses("HOT")
		hots.sort_custom(func(x, y): return x.time_left > y.time_left)
		_set_info("\n".join(hots.map(func(s): return "%s %.1fs" % [s.label.to_upper(), s.time_left])), true)
	elif not dead:
		_set_info(("BOSS · " if is_boss else "") + "%s ARMOR" % armor_type, false)

	# Sprite tint + idle breathing
	if dead:
		sprite.modulate = Color(0.4, 0.3, 0.3)
	elif bursting:
		var p := sin(t * 10.0) * 0.5 + 0.5
		sprite.modulate = Color(1.0 + 0.6 * p, 0.55 + 0.2 * (1.0 - p), 0.55 + 0.2 * (1.0 - p))
	elif hovered:
		sprite.modulate = Color(1.3, 1.3, 1.25)
	else:
		sprite.modulate = Color.WHITE
	if not dead:
		sprite.scale = Vector2(1.0, 1.0 + 0.012 * sin(t * 2.2 + index))
	modulate = Color(0.75, 0.75, 0.75) if dead else Color.WHITE
