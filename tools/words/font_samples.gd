extends SceneTree
# Renders the three font slots next to alternatives into one PNG (Phase H, #61).
# godot --path <repo> --script font_samples.gd -- <fonts dir> <out.png>

const SLOTS := [
	{"title": "TITLES  (now: Pirata One)", "size": 64, "color": Color(0.85, 0.2, 0.18),
		"text": "PYTHIO  ·  The Baron's bounty",
		"fonts": [["Pirata One (now)", "res://assets/fonts/pirata-one-latin-400-normal.woff2"],
			["Grenze Gotisch", "grenze-gotisch.woff2"], ["IM Fell English SC", "im-fell-english-sc.woff2"],
			["New Rocker", "new-rocker.woff2"]]},
	{"title": "UI  (now: Oswald)", "size": 34, "color": Color(0.93, 0.89, 0.81),
		"text": "TAKE THE JOB   Round 7   Flash Heal · 20 mana   BATTLEFIELD RULES",
		"fonts": [["Oswald (now)", "res://assets/fonts/oswald-latin-500-normal.woff2"],
			["Barlow Condensed", "barlow-condensed.woff2"], ["Roboto Condensed", "roboto-condensed.woff2"],
			["Fjalla One", "fjalla-one.woff2"]]},
	{"title": "PYTHIO'S LINES  (now: Special Elite)", "size": 28, "color": Color(0.78, 0.75, 0.68),
		"text": "I charge by the hour. Try not to bleed by the minute.",
		"fonts": [["Special Elite (now)", "res://assets/fonts/special-elite-latin-400-normal.woff2"],
			["Courier Prime", "courier-prime.woff2"], ["Cutive Mono", "cutive-mono.woff2"],
			["IM Fell English", "im-fell-english.woff2"]]},
]

var _frames := 0
var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0]
	_out = args[1]
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.05)
	bg.size = Vector2(1920, 1080)
	root.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(40, 30)
	col.add_theme_constant_override("separation", 6)
	root.add_child(col)
	var small := FontFile.new()
	small.load_dynamic_font(ProjectSettings.globalize_path("res://assets/fonts/oswald-latin-500-normal.woff2"))
	for slot in SLOTS:
		var head := Label.new()
		head.text = slot.title
		head.add_theme_font_override("font", small)
		head.add_theme_font_size_override("font_size", 22)
		head.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
		col.add_child(head)
		for f in slot.fonts:
			var path: String = f[1]
			var font := FontFile.new()
			font.load_dynamic_font(ProjectSettings.globalize_path(path) if path.begins_with("res://") else dir.path_join(path))
			var row := HBoxContainer.new()
			var name := Label.new()
			name.text = f[0]
			name.custom_minimum_size = Vector2(250, 0)
			name.add_theme_font_override("font", small)
			name.add_theme_font_size_override("font_size", 18)
			name.add_theme_color_override("font_color", Color(0.6, 0.57, 0.52))
			name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(name)
			var sample := Label.new()
			sample.text = slot.text
			sample.add_theme_font_override("font", font)
			sample.add_theme_font_size_override("font_size", slot.size)
			sample.add_theme_color_override("font_color", slot.color)
			row.add_child(sample)
			col.add_child(row)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 26)
		col.add_child(gap)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10:
		root.get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false
