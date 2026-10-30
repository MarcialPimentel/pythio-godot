# ui/Backdrop.gd
# The Contract Road (docs/art-direction.md section 2, decided 2026-10-30): every job happens
# somewhere on the road. Each stretch between Barons is an act with its own place, and the
# place changes when the threats do:
#   rounds 1–4 the Mudroad · 6–9 the Drowned Marsh (debuffs start) · 11–14 the Plague Chapel
#   every Baron round: the Crimson Keep · then the road loops, a little darker each lap.
#
# The places are drawn here in code as stand-ins (grey ink silhouettes, crosshatching, fog,
# rain, ash, embers). A painted backdrop replaces one by file name, no code change:
#   assets/art/backdrops/<act id>.png   (3840x2160, see docs/art-assets.md)
#
# Tone rule: the place is mood, never information. Backdrops stay grey and dim and never use the
# meaning colours (green, blue, gold, cyan, violet); only the Keep leans to a muted red.
class_name Backdrop
extends Control

const DESIGN := Vector2(1920, 1080)
## Where the ground meets the sky (fighters' feet are at about y 560).
const HORIZON := 470.0
const ART_DIR := "res://assets/art/backdrops/"

const MUDROAD := "mudroad"
const MARSH := "marsh"
const CHAPEL := "chapel"
const KEEP := "keep"
## The three acts between Barons, in road order.
const ROAD := [MUDROAD, MARSH, CHAPEL]

## Names on screen (Marz kept these, 2026-10-30; Phase H may rename them).
const NAMES := {
	MUDROAD: "The Mudroad", MARSH: "The Drowned Marsh", CHAPEL: "The Plague Chapel", KEEP: "The Crimson Keep",
}
const NUMERALS := {MUDROAD: "I", MARSH: "II", CHAPEL: "III"}

## Colours per place: sky top/mid/horizon, far hills, near silhouettes, ground top/bottom,
## fog tint. All desaturated; tune here.
const LOOK := {
	MUDROAD: {"sky": [Color("141110"), Color("2b231d"), Color("4a3b2e")], "far": Color("2a231e"),
		"near": Color("120e0c"), "ground": [Color("2a221b"), Color("0c0a08")], "fog": Color("c8bca5"), "moon": 0.16},
	MARSH: {"sky": [Color("0f1211"), Color("1e241f"), Color("39402f")], "far": Color("222822"),
		"near": Color("0c0f0c"), "ground": [Color("1b201b"), Color("080a08")], "fog": Color("96a082"), "moon": 0.10},
	CHAPEL: {"sky": [Color("121114"), Color("221f22"), Color("3d3633")], "far": Color("231f20"),
		"near": Color("0e0c0d"), "ground": [Color("221d1c"), Color("0a0909")], "fog": Color("a8a09a"), "moon": 0.12},
	KEEP: {"sky": [Color("120a0a"), Color("25110f"), Color("3a1a17")], "far": Color("241a18"),
		"near": Color("140d0c"), "ground": [Color("261b18"), Color("0c0807")], "fog": Color("78463c"), "moon": 0.0},
}

## Each lap of the road (after round 15, 30 …) the places get this much darker, down to MIN_LIGHT.
@export var lap_darkening := 0.12
@export var min_light := 0.6

var act := MUDROAD
var lap := 0
var _art: Node2D
var _painted: Sprite2D
var _weather: Node2D
var _fade: Tween


## Which place a round happens in (the Baron's rounds are always the Keep).
static func act_for_round(round_num: int) -> String:
	if DifficultySystem.is_boss_round(round_num):
		return KEEP
	var every := maxi(1, DifficultySystem.boss_every)
	return ROAD[((maxi(1, round_num) - 1) / every) % ROAD.size()]


## How many times the road has looped by this round (0 on the first lap).
static func lap_for_round(round_num: int) -> int:
	var every := maxi(1, DifficultySystem.boss_every)
	return ((maxi(1, round_num) - 1) / every) / ROAD.size()


## "ACT I · THE MUDROAD", or "THE CRIMSON KEEP" for the Baron.
static func act_title(act_id: String) -> String:
	var name: String = NAMES.get(act_id, "")
	if NUMERALS.has(act_id):
		return ("Act %s · %s" % [NUMERALS[act_id], name]).to_upper()
	return name.to_upper()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = Node2D.new()
	_art.name = "Art"
	_art.draw.connect(_paint)
	add_child(_art)
	_weather = Node2D.new()
	_weather.name = "Weather"
	_art.add_child(_weather)
	add_child(_make_vignette())
	resized.connect(_fit)
	_fit()
	_apply()


## Show the place for this round; fades through dark when the place changes.
func show_round(round_num: int, animate: bool = true) -> void:
	set_act(act_for_round(round_num), lap_for_round(round_num), animate)


func set_act(act_id: String, lap_num: int = 0, animate: bool = true) -> void:
	if act_id == act and lap_num == lap and _art:
		return
	act = act_id
	lap = lap_num
	if not _art:
		return
	if not animate or not is_inside_tree():
		_apply()
		return
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_art, "modulate:a", 0.0, 0.35)
	_fade.tween_callback(_apply)
	_fade.tween_property(_art, "modulate:a", 1.0, 0.6)


## Cover the whole window (any shape) with the 1920x1080 picture, centred.
func _fit() -> void:
	if not _art:
		return
	var s := maxf(size.x / DESIGN.x, size.y / DESIGN.y)
	if s <= 0.0:
		s = 1.0
	_art.scale = Vector2(s, s)
	_art.position = (size - DESIGN * s) / 2.0


func _apply() -> void:
	var light := maxf(min_light, 1.0 - lap_darkening * lap)
	_art.modulate = Color(light, light, light, _art.modulate.a)
	var tex_path := ART_DIR + act + ".png"
	var painted: Texture2D = load(tex_path) if ResourceLoader.exists(tex_path) else null
	if painted:
		if not _painted:
			_painted = Sprite2D.new()
			_painted.centered = false
			_art.add_child(_painted)
			_art.move_child(_painted, 0)
		_painted.texture = painted
		_painted.scale = DESIGN / painted.get_size()
		_painted.visible = true
	elif _painted:
		_painted.visible = false
	_make_weather()
	_art.queue_redraw()


## True when a painted image is shown instead of the code-drawn stand-in.
func is_painted() -> bool:
	return _painted != null and _painted.visible


# ── Drawing (design space, 1920x1080) ──────────────────

func _paint() -> void:
	if is_painted():
		return
	var L: Dictionary = LOOK[act]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(act)
	_sky(L)
	_moon(L)
	_hatch(Rect2(0, 0, DESIGN.x, HORIZON + 40), deg_to_rad(108), 11.0, Color(0, 0, 0, 0.16))
	_ridge(rng, HORIZON - 40, 80.0, L.far, 40.0)
	_ground(rng, L)
	match act:
		MUDROAD: _mudroad(rng, L)
		MARSH: _marsh(rng, L)
		CHAPEL: _chapel(rng, L)
		KEEP: _keep(rng, L)


func _sky(L: Dictionary) -> void:
	var c: Array = L.sky
	_vgrad(Rect2(0, 0, DESIGN.x, HORIZON * 0.55), c[0], c[1])
	_vgrad(Rect2(0, HORIZON * 0.55, DESIGN.x, HORIZON * 0.45 + 2), c[1], c[2])


func _moon(L: Dictionary) -> void:
	var a: float = L.moon
	if a <= 0.0:
		return
	for i in 14:
		var k := float(i) / 14.0
		_art.draw_circle(Vector2(1390, 150), lerpf(420.0, 30.0, k), Color(0.86, 0.8, 0.7, a * 0.09))


func _ground(rng: RandomNumberGenerator, L: Dictionary) -> void:
	var g: Array = L.ground
	_vgrad(Rect2(0, HORIZON, DESIGN.x, DESIGN.y - HORIZON), g[0], g[1])
	var strokes := PackedVector2Array()
	for i in 90:
		var y := HORIZON + 10.0 + pow(rng.randf(), 0.7) * (DESIGN.y - HORIZON)
		var x := rng.randf() * DESIGN.x
		var w := 30.0 + rng.randf() * 160.0
		strokes.append(Vector2(x, y))
		strokes.append(Vector2(x + w, y + rng.randf_range(-4, 4)))
	_art.draw_multiline(strokes, Color(0, 0, 0, 0.5), 2.0)
	_art.draw_line(Vector2(0, HORIZON), Vector2(DESIGN.x, HORIZON), Color(0, 0, 0, 0.9), 3.0)


func _mudroad(rng: RandomNumberGenerator, L: Dictionary) -> void:
	# A far town on the ridge, a few windows still lit (dull, never gold).
	for i in 10:
		var x := 1080.0 + i * 26.0 + rng.randf() * 8.0
		var h := 22.0 + rng.randf() * 42.0
		_art.draw_rect(Rect2(x, HORIZON - 52 - h, 22, h + 14), Color("17120f"))
		if rng.randf() < 0.35:
			_art.draw_rect(Rect2(x + 8, HORIZON - 52 - h + 10, 5, 7), Color(0.79, 0.59, 0.35, 0.38))
	_ridge(rng, HORIZON + 6, 46.0, L.near, 60.0)
	for t in [[170.0, 1.0], [80.0, 0.75], [1720.0, 1.1], [1840.0, 0.8]]:
		_tree(rng, Vector2(t[0], HORIZON + 10), 150.0 * t[1], -PI / 2.0, 13.0 * t[1], 7, L.near)
	# A gallows signpost on the right.
	var ink := Color("070605")
	_art.draw_line(Vector2(1560, HORIZON + 8), Vector2(1560, HORIZON - 230), ink, 12.0)
	_art.draw_line(Vector2(1554, HORIZON - 230), Vector2(1670, HORIZON - 230), ink, 12.0)
	_art.draw_line(Vector2(1648, HORIZON - 230), Vector2(1648, HORIZON - 175), ink, 3.0)
	_art.draw_circle(Vector2(1648, HORIZON - 164), 11.0, ink)
	# The road: two ruts running towards the viewer.
	_art.draw_line(Vector2(840, HORIZON), Vector2(470, DESIGN.y), Color(0, 0, 0, 0.45), 6.0)
	_art.draw_line(Vector2(1080, HORIZON), Vector2(1450, DESIGN.y), Color(0, 0, 0, 0.45), 6.0)


func _marsh(rng: RandomNumberGenerator, L: Dictionary) -> void:
	_ridge(rng, HORIZON + 2, 30.0, L.near, 50.0)
	# Black water with faint reflections across the middle distance.
	_art.draw_rect(Rect2(0, HORIZON - 6, DESIGN.x, 70), Color("0a0c0a"))
	var glints := PackedVector2Array()
	for i in 46:
		var y := HORIZON + rng.randf() * 58.0
		var x := rng.randf() * DESIGN.x
		glints.append(Vector2(x, y))
		glints.append(Vector2(x + 30.0 + rng.randf() * 90.0, y))
	_art.draw_multiline(glints, Color(0.62, 0.66, 0.56, 0.08), 2.0)
	for t in [[250.0, 1.0], [1650.0, 1.15], [1490.0, 0.7], [90.0, 0.8]]:
		_tree(rng, Vector2(t[0], HORIZON + 20), 120.0 * t[1], -PI / 2.0 + rng.randf_range(-0.25, 0.25), 15.0 * t[1], 5, L.near)
	# Reeds at the edges, leaving the middle clear for the party.
	var reeds := PackedVector2Array()
	for i in 170:
		var x := rng.randf() * DESIGN.x
		if x > 500.0 and x < 1420.0 and rng.randf() < 0.85:
			continue
		var h := 40.0 + rng.randf() * 100.0
		var base := Vector2(x, HORIZON + 60 + rng.randf() * 40.0)
		reeds.append(base)
		reeds.append(base + Vector2(rng.randf_range(-18, 18), -h))
	_art.draw_multiline(reeds, L.near, 3.0)


func _chapel(rng: RandomNumberGenerator, L: Dictionary) -> void:
	_ridge(rng, HORIZON + 4, 34.0, L.near, 60.0)
	var stone := Color("100e0f")
	# The broken chapel on the left: a wall, a pointed window, half a tower.
	_art.draw_rect(Rect2(150, HORIZON - 250, 330, 262), stone)
	_art.draw_rect(Rect2(200, HORIZON - 380, 90, 140), stone)
	_art.draw_colored_polygon(PackedVector2Array([Vector2(196, HORIZON - 380), Vector2(245, HORIZON - 450), Vector2(294, HORIZON - 380)]), stone)
	_art.draw_colored_polygon(PackedVector2Array([Vector2(330, HORIZON - 120), Vector2(330, HORIZON - 200), Vector2(365, HORIZON - 240),
		Vector2(400, HORIZON - 200), Vector2(400, HORIZON - 120)]), Color(L.sky[2], 0.55))
	_art.draw_colored_polygon(PackedVector2Array([Vector2(480, HORIZON - 250), Vector2(530, HORIZON - 170), Vector2(500, HORIZON - 90),
		Vector2(540, HORIZON + 12), Vector2(480, HORIZON + 12)]), stone)   # broken wall end
	# Gravestones and crosses on the right.
	for i in 11:
		var x := 1300.0 + i * 52.0 + rng.randf() * 20.0
		var h := 34.0 + rng.randf() * 40.0
		var lean := rng.randf_range(-0.12, 0.12)
		var base := Vector2(x, HORIZON + 30 + rng.randf() * 30.0)
		if rng.randf() < 0.4:
			_art.draw_line(base, base + Vector2(lean * h, -h - 20), stone, 7.0)
			_art.draw_line(base + Vector2(lean * h - 16, -h + 2), base + Vector2(lean * h + 16, -h + 2), stone, 7.0)
		else:
			_art.draw_rect(Rect2(base.x - 14, base.y - h, 28, h), stone)
			_art.draw_circle(Vector2(base.x, base.y - h), 14.0, stone)
	_tree(rng, Vector2(1790, HORIZON + 14), 160.0, -PI / 2.0, 14.0, 7, L.near)


func _keep(rng: RandomNumberGenerator, L: Dictionary) -> void:
	var stone := Color("120c0b")
	# A hall of arches: pillars with pointed arches between them.
	for i in 7:
		var x := 40.0 + i * 320.0
		_art.draw_rect(Rect2(x, 70, 70, HORIZON - 58), stone)
		var arch := PackedVector2Array()
		for k in 17:
			var a := PI + PI * float(k) / 16.0
			arch.append(Vector2(x + 195.0 + cos(a) * 125.0, 260.0 + sin(a) * 150.0))
		arch.append(Vector2(x + 320, 60))
		arch.append(Vector2(x + 70, 60))
		_art.draw_colored_polygon(arch, stone)
	_art.draw_rect(Rect2(0, 0, DESIGN.x, 72), stone)
	_hatch(Rect2(0, 0, DESIGN.x, HORIZON), deg_to_rad(120), 7.0, Color(0, 0, 0, 0.22))
	# Torn crimson banners (the only red place: red already means danger).
	for i in 6:
		var x := 150.0 + i * 320.0
		var banner := PackedVector2Array([Vector2(x, 150), Vector2(x + 86, 150), Vector2(x + 86, 360),
			Vector2(x + 60, 330), Vector2(x + 43, 372), Vector2(x + 22, 334), Vector2(x, 360)])
		_art.draw_colored_polygon(banner, Color("3a1416"))
		_art.draw_polyline(banner + PackedVector2Array([banner[0]]), Color.BLACK, 3.0)
	# Braziers at both ends, with a warm glow (ember orange, braziers only).
	for x in [130.0, 1790.0]:
		for k in 12:
			_art.draw_circle(Vector2(x, HORIZON - 70), lerpf(240.0, 20.0, k / 12.0), Color(0.82, 0.4, 0.23, 0.035))
		_art.draw_rect(Rect2(x - 26, HORIZON - 68, 52, 78), Color("080505"))
		_art.draw_rect(Rect2(x - 40, HORIZON - 80, 80, 16), Color("080505"))


# ── Drawing helpers ────────────────────────────────────

func _vgrad(r: Rect2, top: Color, bottom: Color) -> void:
	_art.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## Parallel ink lines across a rectangle (crosshatching).
func _hatch(r: Rect2, angle: float, gap: float, col: Color) -> void:
	var d := Vector2(cos(angle), sin(angle))
	var run := r.size.y / maxf(0.2, absf(d.y))
	var lines := PackedVector2Array()
	var x := r.position.x - absf(d.x) * run
	while x < r.end.x:
		var a := Vector2(x, r.position.y)
		lines.append(a)
		lines.append(a + d * run)
		x += gap
	_art.draw_multiline(lines, col, 1.2)


## A ragged hill line filled down to the horizon, with short ink strokes for texture.
func _ridge(rng: RandomNumberGenerator, base: float, amp: float, col: Color, step: float) -> void:
	var bottom := maxf(HORIZON, base + amp) + 12.0   # always below the ragged line
	var pts := PackedVector2Array([Vector2(0, bottom)])
	var x := 0.0
	while x <= DESIGN.x + step:
		pts.append(Vector2(x, base + sin(x / 260.0 + rng.randf() * 0.4) * amp * 0.5 + rng.randf_range(-0.5, 0.5) * amp))
		x += step
	pts.append(Vector2(DESIGN.x + step, bottom))
	_art.draw_colored_polygon(pts, col)
	_art.draw_polyline(pts.slice(1, pts.size() - 1), Color(0, 0, 0, 0.85), 3.0)
	var ticks := PackedVector2Array()
	for i in 160:
		var p := Vector2(rng.randf() * DESIGN.x, base + rng.randf_range(0.2, 1.0) * absf(bottom - base))
		ticks.append(p)
		ticks.append(p + Vector2(-5, 9))
	_art.draw_multiline(ticks, Color(0, 0, 0, 0.3), 1.2)


## A bare tree: a trunk that splits into thinner branches.
func _tree(rng: RandomNumberGenerator, from: Vector2, length: float, angle: float, width: float, depth: int, col: Color) -> void:
	if depth <= 0 or length < 6.0:
		return
	var to := from + Vector2(cos(angle), sin(angle)) * length
	_art.draw_line(from, to, col, width)
	var n := 2 if depth > 3 else 2 + int(rng.randf() < 0.4)
	for i in n:
		_tree(rng, to, length * rng.randf_range(0.62, 0.8), angle + rng.randf_range(-0.55, 0.55), width * 0.66, depth - 1, col)


func _make_vignette() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.75)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.05, 1.0)
	var v := TextureRect.new()
	v.name = "Vignette"
	v.texture = tex
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


# ── Weather: fog everywhere, plus rain (marsh), ash (chapel) or embers (keep) ──

func _make_weather() -> void:
	for c in _weather.get_children():
		_weather.remove_child(c)   # free the name, so the new layer keeps it
		c.queue_free()
	var L: Dictionary = LOOK[act]
	var fog := _particles("Fog", 9, 40.0, _dot(128), Rect2(-200, HORIZON - 120, DESIGN.x + 200, 260))
	fog.direction = Vector2(1, 0)
	fog.spread = 8.0
	fog.initial_velocity_min = 8.0
	fog.initial_velocity_max = 20.0
	fog.scale_amount_min = 3.0
	fog.scale_amount_max = 5.0
	fog.color = Color(L.fog, 0.07 if act != MARSH else 0.1)
	match act:
		MARSH:
			var rain := _particles("Rain", 240, 0.7, _streak(), Rect2(-200, -60, DESIGN.x + 400, 20))
			rain.direction = Vector2(-0.18, 1)
			rain.spread = 2.0
			rain.initial_velocity_min = 1400.0
			rain.initial_velocity_max = 1700.0
			rain.particle_flag_align_y = true
			rain.color = Color(0.75, 0.78, 0.74, 0.22)
		CHAPEL:
			var ash := _particles("Ash", 80, 12.0, _dot(16), Rect2(0, -40, DESIGN.x, 20))
			ash.direction = Vector2(0.3, 1)
			ash.spread = 25.0
			ash.initial_velocity_min = 25.0
			ash.initial_velocity_max = 60.0
			ash.scale_amount_min = 0.25
			ash.scale_amount_max = 0.5
			ash.color = Color(0.7, 0.68, 0.66, 0.45)
		KEEP:
			var embers := _particles("Embers", 60, 7.0, _dot(16), Rect2(0, DESIGN.y - 40, DESIGN.x, 40))
			embers.direction = Vector2(0, -1)
			embers.spread = 20.0
			embers.initial_velocity_min = 40.0
			embers.initial_velocity_max = 110.0
			embers.scale_amount_min = 0.15
			embers.scale_amount_max = 0.35
			embers.color = Color(0.91, 0.5, 0.27, 0.6)


func _particles(n: String, amount: int, life: float, tex: Texture2D, area: Rect2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = n
	p.amount = amount
	p.lifetime = life
	p.preprocess = life   # already in the air when the place appears
	p.texture = tex
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.position = area.get_center()
	p.gravity = Vector2.ZERO
	_weather.add_child(p)
	p.emitting = true
	return p


static func _dot(px: int) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = px
	t.height = px
	return t


static func _streak() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = 2
	t.height = 26
	return t
