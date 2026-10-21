# autoload/systems/Leaderboard.gd
# Talks to web/leaderboard_godot.php on marz.gg.
# In the browser build it calls the copy sitting next to the game; in the editor or a
# desktop build it calls the live site (desktop_url).
extends Node

signal top_loaded(ok: bool, entries: Array)
signal submitted(ok: bool, rank: int, entries: Array, message: String)

## Used when the game isn't running in a browser (editor / desktop builds).
@export var desktop_url: String = "https://marz.gg/games/pythio-godot/leaderboard_godot.php"
@export var timeout_seconds: float = 8.0

const NAME_FILE := "user://player_name.cfg"

var entries: Array = []
var _endpoint: String = ""


func _ready() -> void:
	_endpoint = desktop_url
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("new URL('leaderboard_godot.php', window.location.href).href", true)
		if typeof(url) == TYPE_STRING and url != "":
			_endpoint = url


func fetch_top() -> void:
	var req := _new_request()
	req.request_completed.connect(func(result, code, _h, body):
		var data = _parse(result, code, body)
		var ok: bool = data != null and data.get("status") == "ok"
		if ok:
			entries = data.get("entries", [])
		top_loaded.emit(ok, entries)
		req.queue_free())
	if req.request(_endpoint + "?action=top") != OK:
		top_loaded.emit(false, entries)
		req.queue_free()


func submit(player_name: String, score: int, round_reached: int, won: bool) -> void:
	save_player_name(player_name)
	var req := _new_request()
	req.request_completed.connect(func(result, code, _h, body):
		var data = _parse(result, code, body)
		var ok: bool = data != null and data.get("status") == "ok"
		if ok:
			entries = data.get("entries", [])
		var msg: String = "" if ok else (data.get("message", "Couldn't reach the leaderboard") if data else "Couldn't reach the leaderboard")
		submitted.emit(ok, int(data.get("rank", 0)) if ok else 0, entries, msg)
		req.queue_free())
	var body := JSON.stringify({"name": player_name, "score": score, "round": round_reached, "won": won})
	var err := req.request(_endpoint + "?action=submit", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		submitted.emit(false, 0, entries, "Couldn't reach the leaderboard")
		req.queue_free()


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
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		return null
	if code >= 400 and not data.has("message"):
		return null
	return data
