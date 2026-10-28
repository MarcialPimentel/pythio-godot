# autoload/systems/SoundSystem.gd
# Sound effects (Phase G, #33). The owner makes the sounds; this plays them by FILE NAME, like
# the art: drop `assets/audio/sfx/<name>.ogg` (or .wav / .mp3) and it plays at the right moment.
# A missing file is simply silent, so the game works before any sound exists.
# Every sound, its file name and when it plays: docs/sound-design.md (keep the two in sync).
# Systems don't call this directly: it listens to EventBus and the other systems' signals.
extends Node

const DIR := "res://assets/audio/sfx/"
const EXTENSIONS := ["ogg", "wav", "mp3"]
const SETTINGS := "user://settings.cfg"

## The game asked for sound `name` (whether or not a file exists yet).
signal requested(name: String)
## A sound file actually played (`name` may be a fallback).
signal played(name: String)

## If a specific sound has no file yet, try this one instead ("" = none).
const FALLBACKS := {
	"cast_heal": "cast_land", "cast_hot": "cast_land", "cast_shield": "cast_land",
	"cast_mitigate": "cast_land", "cast_other": "cast_land",
	"debuff_poison": "debuff", "debuff_bleed": "debuff", "debuff_hex": "debuff", "debuff_dread": "debuff",
	"passive_proc": "combo",
	"dread_kill": "fighter_death",
	"baron_arrive": "round_start",
	"bounty": "pick_screen",
}
## The same sound can't start again within this many seconds (stops a wall of noise).
const MIN_GAP := 0.06
## Simultaneous sounds.
const VOICES := 10

## 0..1, saved per device. Changed from the Escape menu.
var volume := 0.8
var muted := false

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last := {}
## The last sound played (for tests).
var last_played := ""
var _countdown_sec := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_load_settings()
	_connect()


# ── Playing ────────────────────────────────────────────

## Plays sound `name` (see docs/sound-design.md). Returns false if there's no file for it.
func play(name: String, volume_db: float = 0.0) -> bool:
	requested.emit(name)
	return _play(name, volume_db)


func _play(name: String, volume_db: float) -> bool:
	var stream := _stream(name)
	if not stream and FALLBACKS.get(name, "") != "":
		return _play(FALLBACKS[name], volume_db)
	if not stream:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last.get(name, -10.0) < MIN_GAP:
		return false
	_last[name] = now
	last_played = name
	played.emit(name)
	if muted or volume <= 0.0:
		return true
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()
	return true


## Is there a file for `name` (or its fallback)?
func has_sound(name: String) -> bool:
	return _stream(name) != null or (FALLBACKS.get(name, "") != "" and has_sound(FALLBACKS[name]))


func _stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var s: AudioStream = null
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [DIR, name, ext]
		if ResourceLoader.exists(path):
			s = load(path)
			break
	_cache[name] = s
	return s


# ── Volume (Escape menu) ───────────────────────────────

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func set_muted(m: bool) -> void:
	muted = m
	_apply_volume()
	_save_settings()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, muted or volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, volume)))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		volume = cfg.get_value("sound", "volume", volume)
		muted = cfg.get_value("sound", "muted", muted)
	_apply_volume()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)   # keep what else is saved there (the "first time" answer)
	cfg.set_value("sound", "volume", volume)
	cfg.set_value("sound", "muted", muted)
	cfg.save(SETTINGS)


# ── When each sound plays ──────────────────────────────

func _connect() -> void:
	# Casting
	SpellSystem.spell_cast_started.connect(func(spell, _t): if spell and spell.cast_time > 0.0: play("cast_start"))
	SpellSystem.spell_cast_failed.connect(func(_s, reason): if reason in ["mana", "cooldown"]: play("cant_cast"))
	EventBus.spell_cast.connect(_on_spell_cast)
	EventBus.combo_fired.connect(func(_t, _l): play("combo"))
	EventBus.passive_triggered.connect(func(_s): play("passive_proc"))
	# Threats
	EventBus.burst_warned.connect(func(_t, _d, _delay, _label): play("burst_warning"))
	EventBus.burst_landed.connect(func(_t, absorbed, dealt): play("burst_hit" if dealt > 0.0 else "shield_absorb"))
	EventBus.shield_ended.connect(func(_t, _s, broken, _r): if broken: play("shield_break"))
	EventBus.debuff_applied.connect(func(_t, status): play("debuff_" + str(status.debuff).to_lower()))
	EventBus.boss_phase.connect(func(_p, _title, _hint): play("baron_phase"))
	EventBus.target_died.connect(func(_t): play("fighter_death"))
	EventBus.dread_struck.connect(func(_t): play("dread_kill"))
	# Your other tools
	EventBus.cleansed.connect(func(_t, count, _s): if count > 0: play("cleanse"))
	CleanseSystem.cleanse_failed.connect(func(reason): if reason == "no_charges": play("cant_cast"))
	BandageSystem.channel_started.connect(func(_t, _d): play("bandage"))
	BandageSystem.bandage_failed.connect(func(reason): if reason == "no_charges": play("cant_cast"))
	# Round flow
	EventBus.round_started.connect(func(r): play("baron_arrive" if DifficultySystem.is_boss_round(r) else "round_start"))
	EventBus.round_cleared.connect(func(_r): play("job_finished"))
	GameManager.game_over.connect(func(_r): play("game_over"))
	GameManager.show_spell_pick.connect(func(_o, r): play("bounty" if DraftSystem.pick_kind(r) == "passive" else "pick_screen"))


func _on_spell_cast(spell: SpellData, _target: Node) -> void:
	if not spell or spell.utility:
		return   # Cleanse has its own sound
	if spell.tags.has(SpellTags.SHIELD):
		play("cast_shield")
	elif spell.tags.has(SpellTags.PROTECT):
		play("cast_mitigate")
	elif spell.tags.has(SpellTags.HOT) and not spell.tags.has(SpellTags.DIRECT):
		play("cast_hot")
	elif spell.tags.has(SpellTags.DIRECT) or spell.tags.has(SpellTags.DELAYED):
		play("cast_heal")
	else:
		play("cast_other")


func _process(_delta: float) -> void:
	# Final countdown: one tick per second in the last 5 seconds (matches the flashing timer).
	if not GameManager.in_round or GameManager.practice:
		_countdown_sec = -1
		return
	var left := GameManager.round_time
	if left <= 0.0 or left > DifficultySystem.final_countdown_time:
		_countdown_sec = -1
		return
	var sec := ceili(left)
	if sec != _countdown_sec:
		_countdown_sec = sec
		play("countdown_tick")


## Low mana (game.gd calls this once per round, when Pythio says "Running on fumes").
func low_mana() -> void:
	play("low_mana")
