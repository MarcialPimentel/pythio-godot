extends SceneTree
const C = preload("res://tools/tests/check.gd")
# "Job finished" (owner, 2026-10-24): after a cleared round a short screen holds and ignores
# input, then the pick or Next party screen opens, and that screen ignores clicks and keys
# for its first moment, so nobody picks a card or starts a round by accident.
# Leaving the run (Escape → Quit/Restart) during the hold cancels it cleanly.
# Pass a path to also save a screenshot of the screen:
#   xvfb-run -a godot --rendering-driver opengl3 --script tools/tests/test_job_finished.gd -- /tmp/jf
var game; var f := 0; var GM; var SS; var DS; var step := 0; var wait := 0.0; var shot := ""
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: shot = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func ids(a): return a.map(func(s): return s.id)
func kit(): return ids(SS.spells) + ids(SS.passives)
func jf_visible() -> bool: return game._job_finished != null and game._job_finished.visible

func TS_count() -> int: return root.get_node("TargetSystem").targets.size()

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); DS = root.get_node("DifficultySystem")
			DS.base_dps = 0.0; DS.burst_interval = 999.0
			P("settings: hold %.1fs, screens ignore input for %.1fs" % [DS.job_finished_time, DS.screen_input_guard])
			game._on_start_pressed(); wait = 0.3
		1:
			game.card_panel._choose(0)   # first spell
			wait = 0.05
		2:
			if not game.party_choice_panel.visible or game.card_panel.visible:
				return false   # wait for the Next party screen to open
			game.party_choice_panel.left_button.emit_signal("pressed")   # a click the moment it opens
			P("Next party screen, click at once: still open=%s (true expected)" % game.party_choice_panel.visible)
			C.ok(game.party_choice_panel.visible, "a click the moment Next party opens does nothing")
			wait = DS.screen_input_guard + 0.1
		3:
			game.party_choice_panel.left_button.emit_signal("pressed")
			P("click after the guard: still open=%s (false expected: the round starts)" % game.party_choice_panel.visible)
			C.ok(not game.party_choice_panel.visible, "a click after the guard starts the round")
			wait = 0.3
		4:
			GM.end_round(true)   # round 1 cleared: a pick round
			wait = 0.3
		5:
			var label: String = game._job_finished.get_node("Box/Title").text if game._job_finished else ""
			P("during the hold: '%s' shown=%s blocks clicks=%s · pick screen=%s party screen=%s" % [label, jf_visible(),
				game._job_finished.mouse_filter == Control.MOUSE_FILTER_STOP, game.card_panel.visible, game.party_choice_panel.visible])
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot + "_job_finished.png"); print("saved job_finished")
			wait = DS.job_finished_time   # ~0.3s past the hold's end: inside the pick screen's guard
		6:
			var before = kit()
			game.card_panel._on_card_pressed(0)
			var k := InputEventKey.new(); k.keycode = KEY_1; k.physical_keycode = KEY_1; k.pressed = true
			Input.parse_input_event(k)
			P("after the hold: shown=%s pick screen=%s · click + key 1 at once: kit %s → %s (unchanged expected)" % [
				jf_visible(), game.card_panel.visible, before, kit()])
			C.eq(kit(), before, "a click or key right as the pick opens picks nothing")
			wait = DS.screen_input_guard + 0.1
		7:
			game.card_panel._on_card_pressed(0)
			wait = 0.4   # the card fades out, then Next party opens
		8:
			P("click after the guard: kit=%s (one more expected) · party screen=%s" % [kit(), game.party_choice_panel.visible])
			wait = DS.screen_input_guard + 0.1
		9:
			game.party_choice_panel.left_button.emit_signal("pressed")
			wait = 0.3
		10:
			GM.end_round(true)   # round 2: not a pick round → Next party after the hold
			wait = 0.3
		11:
			P("round 2 cleared: shown=%s party screen=%s (true, false expected)" % [jf_visible(), game.party_choice_panel.visible])
			C.ok(jf_visible() and not game.party_choice_panel.visible, "Job finished holds before Next party")
			paused = true   # pausing during the hold must hold it too
			set_meta("pz", true)
			wait = DS.job_finished_time + 0.3
		12:
			if has_meta("pz"):
				C.ok(jf_visible() and not game.party_choice_panel.visible, "the hold waits while the game is paused")
				paused = false; remove_meta("pz")
				wait = DS.job_finished_time
				return false
			P("after the hold: shown=%s party screen=%s (false, true expected)" % [jf_visible(), game.party_choice_panel.visible])
			C.ok(not jf_visible() and game.party_choice_panel.visible, "Next party opens after the hold")
			wait = DS.screen_input_guard + 0.1
		13:
			game.party_choice_panel.left_button.emit_signal("pressed")
			wait = 0.3
		14:
			GM.end_round(true)   # round 3 cleared, then quit to title during the hold
			wait = 0.3
		15:
			game._leave_run()
			wait = DS.job_finished_time + 0.5
		16:
			P("quit to title during the hold: shown=%s pick screen=%s party screen=%s in_round=%s (all false expected)" % [
				jf_visible(), game.card_panel.visible, game.party_choice_panel.visible, GM.in_round])
			C.ok(not jf_visible() and not game.card_panel.visible and not game.party_choice_panel.visible and not GM.in_round, "quitting during the hold leaves nothing behind")
			game._on_start_pressed(); wait = 0.3
		17:
			# Pick a card, then quit to title before its fade-out finishes (review 2026-10-28).
			game.card_panel._choose(0)
			game._leave_run()
			wait = 0.6
		18:
			C.ok(not game.party_choice_panel.is_visible_in_tree(), "a pick cancelled by quitting doesn't open Next party")
			var sp := InputEventKey.new(); sp.keycode = KEY_SPACE; sp.pressed = true
			game.party_choice_panel._unhandled_input(sp)
			wait = 0.3
		19:
			C.ok(not GM.in_round and TS_count() == 0, "Space on the title screen doesn't start a hidden round")
			C.done(self)
	step += 1
	return false
