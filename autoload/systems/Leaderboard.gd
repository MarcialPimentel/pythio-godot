# autoload/systems/Leaderboard.gd
# Talks to web/leaderboard_godot.php on marz.gg.
# In the browser build it calls the copy sitting next to the game; in the editor or a
# desktop build it calls the live site (desktop_url).
extends Node

signal top_loaded(ok: bool, entries: Array)

## Boards from the server, newest first: [{id, title, kind, current}]. A new board starts
## only when scoring changes; older ones stay browsable (◀ ▶ on the start screen).
var boards: Array = []
## The board currently shown, and how its rows read ("healing" or "classic").
var board_id: String = ""
var board_kind: String = "healing"
var board_title: String = ""
signal submitted(ok: bool, rank: int, entries: Array, message: String)

## Used when the game isn't running in a browser (editor / desktop builds).
@export var desktop_url: String = "https://marz.gg/games/pythio/leaderboard_godot.php"
@export var timeout_seconds: float = 8.0

const NAME_FILE := "user://player_name.cfg"

var entries: Array = []
var _endpoint: String = ""
## The server's one-time ticket for the run being played ("" = none yet, or offline).
## A score can only be posted with the ticket from the start of its run.
var run_ticket: String = ""


func _ready() -> void:
	_endpoint = desktop_url
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("new URL('leaderboard_godot.php', window.location.href).href", true)
		if typeof(url) == TYPE_STRING and url != "":
			_endpoint = url
	GameManager.show_spec_choice.connect(start_run)   # a new run begins


## Asks the server for this run's ticket (quietly; offline just means it can't be posted).
func start_run() -> void:
	run_ticket = ""
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		return   # automated tests don't take tickets from the live server
	var req := _new_request()
	req.request_completed.connect(func(result, code, _h, body):
		var data = _parse(result, code, body)
		if data != null and data.get("status") == "ok":
			run_ticket = str(data.get("run", ""))
		req.queue_free())
	if req.request(_endpoint + "?action=start", [], HTTPClient.METHOD_POST, "") != OK:
		req.queue_free()


## Loads a board's top 10 (`board` = "" for the current one).
func fetch_top(board: String = "") -> void:
	var req := _new_request()
	req.request_completed.connect(func(result, code, _h, body):
		var data = _parse(result, code, body)
		var ok: bool = data != null and data.get("status") == "ok"
		if ok:
			entries = data.get("entries", [])
			_read_board(data)
		top_loaded.emit(ok, entries)
		req.queue_free())
	if req.request(_endpoint + "?action=top" + ("&board=" + board.uri_encode() if board != "" else "")) != OK:
		top_loaded.emit(false, entries)
		req.queue_free()


## Posts a run: rounds survived, then effective healing (the board ranks by both).
func submit(player_name: String, rounds: int, healing: int) -> void:
	save_player_name(player_name)
	var req := _new_request()
	req.request_completed.connect(func(result, code, _h, body):
		var data = _parse(result, code, body)
		var ok: bool = data != null and data.get("status") == "ok"
		if ok:
			entries = data.get("entries", [])
			_read_board(data)
		var msg: String = "" if ok else (data.get("message", "Couldn't reach the leaderboard") if data else "Couldn't reach the leaderboard")
		if ok:
			run_ticket = ""   # used up
		submitted.emit(ok, int(data.get("rank", 0)) if ok else 0, entries, msg)
		req.queue_free())
	var build := str(ProjectSettings.get_setting("application/config/version", "dev")).replace("·", "/")
	var body := JSON.stringify({"name": player_name, "rounds": rounds, "healing": healing, "build": build, "run": run_ticket})
	var err := req.request(_endpoint + "?action=submit", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		submitted.emit(false, 0, entries, "Couldn't reach the leaderboard")
		req.queue_free()


func _read_board(data: Dictionary) -> void:
	boards = data.get("boards", boards)
	board_id = str(data.get("board", board_id))
	board_kind = str(data.get("kind", "healing"))
	board_title = str(data.get("title", ""))


## The board `step` places away from the one shown (−1 = newer, +1 = older), or "".
func neighbour_board(step: int) -> String:
	var i := boards.map(func(b): return b.get("id", "")).find(board_id)
	var j := i + step
	return boards[j].get("id", "") if i != -1 and j >= 0 and j < boards.size() else ""


func load_player_name() -> String:
	var cfg := ConfigFile.new()
	return cfg.get_value("player", "name", "") if cfg.load(NAME_FILE) == OK else ""


func save_player_name(player_name: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.save(NAME_FILE)


func _new_request() -> HTTPRequest:
	var req := HTTPRequest.new()
	req.timeout = timeout_seconds
	add_child(req)
	return req


func _parse(result: int, code: int, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		return null
	# A host error page or a firewall check isn't JSON. Treat it as "no reply" quietly
	# (JSON.parse_string would log an ERROR line for it).
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = json.data
	if code >= 400 and not data.has("message"):
		return null
	return data
