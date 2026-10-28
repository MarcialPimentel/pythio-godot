extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Sound (Phase G, #33): sounds play by file name from assets/audio/sfx/ and a missing file is
# silent. Checks which sound each moment asks for (casts by tag, combo, burst warning, debuff
# with its fallback, cleanse, round start, final countdown ticks, Job finished), the volume
# and mute settings, and that the Escape menu has the controls.
# Works with or without sound files: "asks" = what the game wants, "plays" = files that exist.
var game; var f := 0; var GM; var SS; var TS; var ES; var SND; var D; var step := 0; var wait := 0.0
var asked := []; var heard := []; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func lib(id): return SS.get_library_spell(id)

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			ES = root.get_node("EffectSystem"); SND = root.get_node("SoundSystem"); D = root.get_node("DifficultySystem")
			D.base_dps = 0.0; D.burst_interval = 999.0; D.job_finished_time = 0.0
			# Record every name the game asks for, file or not.
			SND.requested.connect(func(n): asked.append(n))
			SND.played.connect(func(n): heard.append(n))
			P("files found: %s" % [["combo", "cast_heal", "cast_land", "debuff_poison", "game_over"].map(func(n): return "%s=%s" % [n, SND.has_sound(n)])])
			game._on_start_pressed(); wait = 0.3
		1:
			game.card_panel._choose(0); wait = 0.5
		2:
			asked.clear(); heard.clear()
			game.party_choice_panel._on_left_chosen(); wait = 0.4
		3:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("round start → %s" % [asked]); asked.clear(); heard.clear()
			GM.mana = 999.0
			ES.cast(lib("flash_heal"), T[0])
			P("Flash Heal → asks %s · plays %s (a file, or its fallback cast_land, if either exists)" % [asked, heard]); asked.clear(); heard.clear()
			wait = 0.1
		4:
			ES.combo(T[0], "Test")
			P("combo → %s" % [asked]); asked.clear(); heard.clear()
			TS.telegraph(T[1], 5.0, 1.0)
			P("burst warning → %s" % [asked]); asked.clear(); heard.clear()
			root.get_node("DebuffSystem").apply(T[2], "POISON")
			P("Poison → asks %s · plays %s (debuff_poison, else debuff)" % [asked, heard]); asked.clear(); heard.clear()
			root.get_node("CleanseSystem").try_cleanse(T[2])
			P("Cleanse → %s" % [asked]); asked.clear(); heard.clear()
			GM.round_time = 5.5
			wait = 6.0
		5:
			var ticks := asked.filter(func(n): return n == "countdown_tick").size()
			P("last 5 seconds → %d countdown ticks (5) · then %s" % [ticks, asked.filter(func(n): return n != "countdown_tick")])
			# Volume and mute
			SND.set_volume(0.5); SND.set_muted(true)
			var bus := AudioServer.get_bus_index("Master")
			P("volume 0.5 + mute → bus muted=%s, saved volume=%s" % [AudioServer.is_bus_mute(bus), ConfigFile.new().load(SND.SETTINGS) == OK])
			SND.set_muted(false); SND.set_volume(0.8)
			P("unmuted at 0.8 → bus muted=%s, %.1f dB" % [AudioServer.is_bus_mute(bus), AudioServer.get_bus_volume_db(bus)])
			var pm = game.get_children().filter(func(c): return c.get_script() and str(c.get_script().resource_path).ends_with("PauseMenu.gd"))
			var has_controls: bool = not pm.is_empty() and pm[0].find_child("Volume", true, false) != null and pm[0].find_child("Mute", true, false) != null
			P("Escape menu has Sound volume and Mute=%s" % has_controls)
			C.done(self)
	step += 1
	return false
