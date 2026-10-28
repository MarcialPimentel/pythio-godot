extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Escape menu: pauses mid-round (timer and damage stop), Resume continues, Quit to title
# ends the run cleanly (no game over, no fighters left), Restart from the Baron fight starts
# a fresh run. Escape does nothing on the title screen.
# Pass a path to also save a screenshot of the menu.
var game; var f := 0; var GM; var TS; var BD; var step := 0; var wait := 0.0; var shot := ""
var t_before := 0.0; var hp_before := 0.0; var overs := 0
func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: shot = a[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func esc():
	var e := InputEventKey.new(); e.keycode = KEY_ESCAPE; e.pressed = true
	Input.parse_input_event(e)
func menu(): return game.get_children().filter(func(c): return c.get_script() and c.get_script().resource_path.ends_with("PauseMenu.gd"))[0]
func hp(): return TS.targets.reduce(func(acc, t): return acc + t.health_comp.current_health, 0.0)

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); BD = root.get_node("BossDirector")
			GM.game_over.connect(func(_a, _b): overs += 1)
			esc(); wait = 0.2
		1:
			P("RESULT title screen ignores Escape=%s" % (not menu().visible and not paused))
			C.ok(not menu().visible and not paused, "Escape does nothing on the title screen")
			game._on_start_pressed(); wait = 0.5
		2:
			game.party_choice_panel._on_left_chosen(); wait = 1.5
		3:
			esc(); wait = 0.1
		4:
			t_before = GM.round_time; hp_before = hp()
			wait = 0.0; step = 5; set_meta("t0", Time.get_ticks_msec()); return false
		5:
			if Time.get_ticks_msec() - get_meta("t0") < 1500: return false
			if shot != "": root.get_viewport().get_texture().get_image().save_png(shot)
			P("RESULT menu open=%s, paused=%s, timer frozen=%s, no damage while paused=%s" % [menu().visible, paused, is_equal_approx(GM.round_time, t_before), is_equal_approx(hp(), hp_before)])
			C.ok(menu().visible and paused, "Escape pauses mid-round"); C.ok(is_equal_approx(GM.round_time, t_before), "timer frozen while paused"); C.ok(is_equal_approx(hp(), hp_before), "no damage while paused")
			esc(); wait = 0.6
		6:
			P("RESULT Escape resumes=%s, timer running=%s" % [not paused and not menu().visible, GM.round_time < t_before - 0.3])
			C.ok(not paused and not menu().visible and GM.round_time < t_before - 0.3, "Escape resumes and the timer runs")
			esc(); wait = 0.1
		7:
			menu()._buttons_for_test()[2].pressed.emit(); wait = 0.3
		8:
			P("RESULT quit to title: start screen=%s, game UI hidden=%s, fighters left=%d, in round=%s, not paused=%s, game overs=%d" % [game.start_screen.visible, not game.game_ui.visible, TS.targets.size(), GM.in_round, not paused, overs])
			C.ok(game.start_screen.visible and not game.game_ui.visible, "Quit goes to the title screen"); C.eq(TS.targets.size(), 0, "no fighters left"); C.ok(not GM.in_round and not paused, "not in a round, not paused"); C.eq(overs, 0, "quitting is not a game over")
			game._on_start_pressed(); wait = 0.5
		9:
			GM.debug_jump_to_round(5); wait = 0.2
		10:
			game.party_choice_panel._on_left_chosen(); wait = 1.0
		11:
			P("Baron fight running=%s" % (BD.boss != null and GM.in_round))
			esc(); wait = 0.1
		12:
			menu()._buttons_for_test()[1].pressed.emit(); wait = 0.6
		13:
			P("RESULT restart: round %d, school pick showing=%s, Baron cleared=%s, spells=%d, game overs=%d" % [GM.current_round, game.card_panel.visible or game._card_mode == "spec" or GM.current_round == 1, BD.boss == null, root.get_node("SpellSystem").spells.size(), overs])
			C.eq(GM.current_round, 1, "Restart begins at round 1"); C.ok(BD.boss == null, "the Baron is cleared"); C.eq(overs, 0, "restarting is not a game over")
			wait = 0.5
		14:
			game.party_choice_panel._on_left_chosen(); wait = 1.0
		15:
			P("RESULT new run plays: in round=%s, fighters=%d" % [GM.in_round, TS.targets.size()])
			C.ok(GM.in_round and TS.targets.size() > 0, "the new run plays")
			C.done(self)
	step += 1
	return false
