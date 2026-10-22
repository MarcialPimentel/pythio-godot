extends SceneTree
# The Crimson Baron fight: arrives at 55% with 2 guards; phase banners at 0 / 40% / 75% of
# the round; assassin strikes only in phase 2; one execution warning in phase 3; random
# bursts never target him; his second visit hits 15% harder.
# Pass a path to also save a screenshot during phase 2.
var game; var f := 0; var GM; var TS; var BD; var EB; var step := 0; var wait := 0.0
var phases := []; var warns := []; var baron; var shot := ""; var shot_done := false; var t0 := 0.0
func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: shot = a[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func now(): return Time.get_ticks_msec() / 1000.0

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); BD = root.get_node("BossDirector"); EB = root.get_node("EventBus")
			EB.boss_phase.connect(func(p, title, _h): phases.append([p, title, snapped(1.0 - GM.round_time / BD._round_length, 0.01)]))
			EB.burst_warned.connect(func(t, dmg, delay, label): warns.append([t.display_name, label, roundi(dmg), delay, snapped(1.0 - GM.round_time / BD._round_length, 0.01)]))
			game._on_start_pressed(); wait = 0.8
		1:
			GM.debug_jump_to_round(5); wait = 0.2
		2:
			P("round 5 card: '%s' — %s" % [game.party_choice_panel.left_name.text, game.party_choice_panel.left_gold.text.replace("\n", ", ")])
			game.party_choice_panel._on_left_chosen(); wait = 0.2
		3:
			baron = TS.targets.filter(func(t): return t.is_boss)[0]
			P("fighters: %s · Baron health %.0f / %.0f (55%%)" % [str(TS.targets.map(func(t): return t.display_name)), baron.health_comp.current_health, baron.health_comp.max_health])
			for t in TS.targets: t.health_comp.invulnerable = true   # watch the whole fight
			Engine.time_scale = 3.0
			t0 = now(); step = 4; return false
		4:
			if not shot_done and shot != "" and BD.phase == 2 and baron.pending_burst_time > 0.5:
				shot_done = true
				Engine.time_scale = 1.0
				root.get_viewport().get_texture().get_image().save_png(shot); print("saved shot")
				Engine.time_scale = 3.0
			if GM.in_round: return false
			Engine.time_scale = 1.0
			P("phases (phase, title, share of round): %s" % str(phases))
			var on_baron := warns.filter(func(w): return w[0] == "Crimson Baron")
			P("hits telegraphed on the Baron (label, damage, warning, when): %s" % str(on_baron.map(func(w): return [w[1], w[2], w[3], w[4]])))
			P("RESULT assassins only in phase 2=%s, one execution in phase 3=%s, no random bursts on him=%s" % [
				on_baron.filter(func(w): return w[1] == "ASSASSIN").all(func(w): return w[4] >= 0.39 and w[4] < 0.76),
				on_baron.filter(func(w): return w[1] == "EXECUTION").size() == 1 and on_baron.filter(func(w): return w[1] == "EXECUTION")[0][4] >= 0.74,
				on_baron.all(func(w): return w[1] != "INCOMING")])
			P("guards got ordinary bursts: %d" % warns.filter(func(w): return w[0] == "Baron's Guard").size())
			warns.clear(); phases.clear()
			GM.debug_jump_to_round(10); wait = 0.3; step = 5; return false
		5:
			game.party_choice_panel._on_left_chosen(); wait = 0.2
		6:
			baron = TS.targets.filter(func(t): return t.is_boss)[0]
			P("visit 2: '%s', Baron max %.0f, factor %.2f, bleed %.1f/s (1200-HP visit-1 Baron: 14.4/s)" % [game.party_choice_panel.left_name.text, baron.health_comp.max_health, BD.visit_factor(), BD.boss_dps(baron)])
			quit()
	step += 1
	return false
