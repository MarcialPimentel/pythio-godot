extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Bandages: Space on a hovered fighter channels 40 healing over 2.5s; no casting while
# channelling; charges (start 3, max 3, +1 after every 2nd round cleared); a death cancels it.
var game; var f := 0; var GM; var SS; var BS; var TS; var step := 0; var wait := 0.0; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func space():
	var e := InputEventKey.new(); e.keycode = KEY_SPACE; e.physical_keycode = KEY_SPACE; e.pressed = true
	Input.parse_input_event(e)

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); BS = root.get_node("BandageSystem"); TS = root.get_node("TargetSystem")
			var DS = root.get_node("DifficultySystem"); DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			DS.job_finished_time = 0.0; DS.screen_input_guard = 0.0   # instant screens (see test_job_finished.gd)
			game._on_start_pressed(); wait = 0.8
		1:
			P("run start: charges=%d/%d label='%s'" % [BS.charges, BS.max_charges, game.hud.bandage_label.get_parsed_text()])
			C.ok(game.hud.bandage_label.get_parsed_text().begins_with("BANDAGES") and game.hud.bandage_label.get_parsed_text().count("■") == BS.charges, "the bandage counter shows the charges")
			space(); wait = 0.1   # Space between rounds takes the job, not a bandage
		2:
			P("Space on the party screen: in_round=%s charges=%d (unchanged)" % [GM.in_round, BS.charges])
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			T[0].health_comp.current_health = 5.0
			T[0].target_button.emit_signal("mouse_entered")
			space(); wait = 0.3
		3:
			var ok: bool = SS.request_cast(SS.spells[0], T[1])
			P("channelling=%s charges=%d cast bar='%s' · casting another spell meanwhile allowed=%s" % [BS.is_channeling(), BS.charges, game.cast_label.text, ok])
			wait = 2.4
		4:
			P("after 2.5s: hp=%.1f (5 + 40 = 45) channelling=%s cast bar visible=%s" % [hp(T[0]), BS.is_channeling(), game.cast_bar.visible])
			T[2].health_comp.current_health = 20.0
			BS.try_bandage(T[2]); wait = 0.5
		5:
			T[2].health_comp.take_damage(999.0)
			wait = 0.1
		6:
			P("fighter died mid-bandage: channelling=%s busy=%s charges=%d" % [BS.is_channeling(), SS.external_busy, BS.charges])
			# charges: 1 left. Clear rounds and watch refills.
			BS.charges = 1; BS.charges_changed.emit(1, 3)
			for r in [1, 2, 3, 4, 5, 6]:
				root.get_node("EventBus").round_cleared.emit(r)
			P("after clearing rounds 1–6 from 1 charge: charges=%d (1 +1 +1 +1, capped at 3)" % BS.charges)
			BS.charges = 0; BS.charges_changed.emit(0, 3); BS.try_bandage(T[1])
			P("no charges: channelling=%s label='%s'" % [BS.is_channeling(), game.hud.bandage_label.get_parsed_text()])
			C.done(self)
	step += 1
	return false
