# ui/ScreenFeel.gd
# Screen-wide feel (Steam polish step 2, docs/art-direction.md section 5): the screen shakes when
# a burst lands (harder for bigger hits), punches in a little when a combo fires, and a dark red
# veil falls when a fighter dies. Fighters' own sparks, shadows and hit flashes are in
# entities/Target.gd. Everything listens to EventBus; nothing here changes the rules.
#
# "Reduce screen shake and flashes" (pause menu) turns the shake and punch off, and halves sparks.
class_name ScreenFeel
extends Node

const SETTINGS := "user://settings.cfg"

## Player setting, saved on this device.
static var reduce_effects := false

## The control that shakes (game.gd passes GameUI).
var stage: Control
## Dark red veil over the battlefield after a death (sits under the game-over panel).
var veil: ColorRect

## How long and how hard the screen shakes, in pixels at 1080p. Tunable here.
@export var shake_time := 0.32
@export var death_shake := 26.0
@export var combo_punch := 1.025

var _shake_left := 0.0
var _shake_px := 0.0
var _shaking := false
var _punch: Tween
var _veil_tween: Tween


static func load_setting() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		reduce_effects = cfg.get_value("display", "reduce_effects", false)


static func set_reduce(on: bool) -> void:
	reduce_effects = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)   # keep what else is saved there (sound, the "first time" answer)
	cfg.set_value("display", "reduce_effects", on)
	cfg.save(SETTINGS)


func _ready() -> void:
	veil = ColorRect.new()
	veil.name = "DeathVeil"
	veil.color = Color(0.1, 0.01, 0.01, 0.0)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.visible = false
	stage.add_child(veil)
	EventBus.burst_landed.connect(_on_burst_landed)
	EventBus.combo_fired.connect(func(_t, _label): punch())
	EventBus.target_died.connect(_on_target_died)
	EventBus.run_started.connect(clear)


func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		var k := maxf(0.0, _shake_left / shake_time)   # fades out
		stage.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_px * k
		_shaking = true
	elif _shaking:
		_shaking = false
		stage.position = Vector2.ZERO


## Shake the screen by up to `px` pixels (ignored with reduce effects on).
func shake(px: float) -> void:
	if reduce_effects or px <= 0.0:
		return
	_shake_px = maxf(px, _shake_px if _shake_left > 0.0 else 0.0)
	_shake_left = shake_time


## A combo: the whole screen leans in for a moment.
func punch() -> void:
	if reduce_effects:
		return
	if _punch:
		_punch.kill()
	stage.pivot_offset = stage.size / 2.0
	stage.scale = Vector2.ONE * combo_punch
	_punch = create_tween()
	_punch.tween_property(stage, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _on_burst_landed(target, absorbed: float, dealt: float) -> void:
	if dealt > 0.0:
		var max_hp: float = target.health_comp.max_health if is_instance_valid(target) and target.get("health_comp") else 100.0
		shake(clampf(dealt / maxf(1.0, max_hp) * 40.0, 6.0, 22.0))
	elif absorbed > 0.0:
		shake(3.0)   # the shield took it: just a tap


func _on_target_died(_t) -> void:
	shake(death_shake)
	veil.visible = true
	stage.move_child(veil, _veil_index())
	if _veil_tween:
		_veil_tween.kill()
	_veil_tween = create_tween()
	_veil_tween.tween_property(veil, "color:a", 0.42, 0.9)


## Just under the game-over panel, so the summary stays bright.
func _veil_index() -> int:
	var panel := stage.get_node_or_null("GameOverPanel")
	var i := panel.get_index() if panel else stage.get_child_count() - 1
	return i - 1 if veil.get_index() < i else i


## A new run (or Play Again): no veil, no shake.
func clear() -> void:
	if _veil_tween:
		_veil_tween.kill()
	veil.color.a = 0.0
	veil.visible = false
	_shake_left = 0.0
	_shaking = false
	stage.position = Vector2.ZERO
	stage.scale = Vector2.ONE
