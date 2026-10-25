extends SceneTree
# Owner, 2026-10-24:
# 1. Every heal-over-time on a fighter is listed under the health bar (one line each), so
#    Renew + Healing Plague visibly stack, and both heal.
# 2. In the last 5 seconds of a round the timer flashes and pops on each whole second; it
#    goes back to normal when the round ends.
# Pass a path to also save screenshots:
#   xvfb-run -a godot --rendering-driver opengl3 --script tools/tests/test_countdown.gd -- /tmp/cd
var game; var f := 0; var GM; var SS; var TS; var DS; var step := 0; var wait := 0.0; var shot := ""
var t; var hp0 := 0.0; var pops := []
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: shot = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func snap(n):
	if shot != "":
		root.get_viewport().get_texture().get_image().save_png(shot + "_" + n + ".png"); print("saved ", n)

func _process(d):
	f += 1
	wait -= d
	if step >= 7 and game._countdown_sec != -1 and not pops.has(game._countdown_sec):
		pops.append(game._countdown_sec)
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem"); DS = root.get_node("DifficultySystem")
			DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0; DS.job_finished_time = 0.0
			game._on_start_pressed(); wait = 0.3
		1:
			game.card_panel._choose(1); wait = 0.5   # Renew
		2:
			game.party_choice_panel._on_left_chosen(); wait = 0.5
		3:
			t = TS.targets[1]
			t.health_comp.max_health = 500.0; t.health_comp.current_health = 100.0
			GM.mana = 999.0; GM.round_time = 30.0
			SS.request_cast(SS.get_library_spell("renew"), t)
			wait = 0.2
		4:
			GM.mana = 999.0
			SS.request_cast(SS.get_library_spell("healing_plague"), t)
			wait = 2.0
		5:
			var lines: PackedStringArray = t.info_label.text.split("\n")
			P("both on the fighter: statuses=%s · label lines=%s" % [t.health_comp.get_statuses("HOT").map(func(s): return s.label), lines])
			hp0 = t.health_comp.current_health
			snap("hots")
			wait = 2.0
		6:
			P("healing over 2s with both: %.0f (Renew 5/s + Plague 4/s = 18)" % (t.health_comp.current_health - hp0))
			P("at %.1fs left: scale=%s modulate=%s (normal expected)" % [GM.round_time, game.timer_label.scale, game.timer_label.modulate])
			GM.round_time = 5.6
			wait = 0.8
		7:
			P("at %.1fs left: countdown on=%s scale=%.2f" % [GM.round_time, game._countdown_sec != -1, game.timer_label.scale.x])
			snap("countdown")
			wait = 5.0   # let the round run out
		8:
			P("seconds that popped: %s (5,4,3,2,1 expected)" % [pops])
			P("after the round: in_round=%s scale=%s modulate=%s countdown=%d (normal, -1 expected)" % [GM.in_round, game.timer_label.scale, game.timer_label.modulate, game._countdown_sec])
			quit()
	step += 1
	return false
