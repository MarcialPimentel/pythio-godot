# ui/LeaderboardView.gd
# The title screen's top 10 (scenes/Game.tscn: StartScreen/LeaderboardPanel), with ◀ ▶ to
# browse older boards. Shows whatever Leaderboard (the online autoload) last loaded.
class_name LeaderboardView
extends Node

var grid: GridContainer
var status: Label
var _nav: HBoxContainer


func _init(p_grid: GridContainer, p_status: Label) -> void:
	grid = p_grid
	status = p_status


func _ready() -> void:
	_make_nav()
	Leaderboard.top_loaded.connect(show_board)


func show_board(ok: bool, entries: Array) -> void:
	_update_nav()
	for c in grid.get_children():
		c.queue_free()
	if not ok:
		status.text = "Leaderboard offline. It works once the game is on marz.gg."
		return
	status.text = "No one yet. Be the first." if entries.is_empty() else ""
	for i in entries.size():
		var e: Dictionary = entries[i]
		var gold := Color(0.95, 0.78, 0.35) if i == 0 else Color(0.9, 0.87, 0.8)
		_cell("%d." % (i + 1), gold)
		_cell(str(e.get("name", "?")), gold, true)
		if Leaderboard.board_kind == "classic":   # old boards: original score, then round reached
			_cell(str(int(e.get("score", 0))), gold)
			_cell("WON" if e.get("won", false) else "R%d" % int(e.get("round", 0)),
				Color(0.45, 0.9, 0.4) if e.get("won", false) else Color(0.6, 0.58, 0.55))
		else:
			_cell("R%d" % int(e.get("rounds", 0)), gold)
			_cell(RunStats.fmt(int(e.get("healing", 0))), Color(0.6, 0.58, 0.55))


func _make_nav() -> void:
	var box := grid.get_parent()
	_nav = HBoxContainer.new()
	_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	_nav.add_theme_constant_override("separation", 10)
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
	_nav.add_child(older); _nav.add_child(title); _nav.add_child(newer)
	_nav.visible = false
	box.add_child(_nav)
	box.move_child(_nav, grid.get_index())


func _switch_board(step: int) -> void:
	var id := Leaderboard.neighbour_board(step)
	if id != "":
		Leaderboard.fetch_top(id)


func _update_nav() -> void:
	if not _nav:
		return
	_nav.visible = Leaderboard.boards.size() > 1
	var current := Leaderboard.boards.any(func(b): return b.get("id") == Leaderboard.board_id and b.get("current", false))
	var title: Label = _nav.get_node("Title")
	title.text = Leaderboard.board_title + ("" if current else "  (old)")
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3) if current else Color(0.7, 0.66, 0.6))
	_nav.get_node("Older").disabled = Leaderboard.neighbour_board(1) == ""
	_nav.get_node("Newer").disabled = Leaderboard.neighbour_board(-1) == ""


func _cell(text: String, color: Color, expand := false) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 24)
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
	grid.add_child(l)
