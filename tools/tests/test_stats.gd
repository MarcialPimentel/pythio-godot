extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Effective healing and the run summary: restored health (no overheal) + shield absorbs +
# prevented damage; overheal %, combos, bandages; the leaderboard payload and rows; local best.
var game; var f := 0; var GM; var SS; var TS; var RS; var BS; var step := 0; var wait := 0.0; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func cast(id: String, t): SS.cooldowns.clear(); SS.request_cast(SS.get_library_spell(id), t)

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			RS = root.get_node("RunStats"); BS = root.get_node("BandageSystem")
			var DS = root.get_node("DifficultySystem"); DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "shield", "divine_protection", "renew", "overgrowth"]))
			GM.mana = 999.0; GM.max_mana = 999.0
			RS.reset()
			T[0].health_comp.current_health = T[0].health_comp.max_health - 20.0
			cast("flash_heal", T[0]); wait = 0.05   # 32 heal, 20 restored, 12 overheal (then saturated)
		3:
			P("Flash Heal with 20 missing: restored=%.0f overheal=%.0f effective=%d overheal%%=%d" % [RS.restored, RS.overheal, RS.effective_healing(), RS.overheal_percent()])
			C.near(RS.restored, 20.0, "Flash Heal restores only the missing 20")
			C.near(RS.overheal, 12.0, "the other 12 counts as overheal")
			cast("shield", T[1]); T[1].health_comp.take_damage(18.0)
			cast("divine_protection", T[2]); T[2].health_comp.take_damage(30.0)
			P("+ Shield absorbs 18, Divine Protection prevents 15: absorbed=%.0f prevented=%.0f effective=%d (20+18+15=53) mitigated=%d" % [RS.absorbed, RS.prevented, RS.effective_healing(), RS.mitigated()])
			C.near(RS.absorbed, 18.0, "the shield absorbed 18")
			C.near(RS.prevented, 15.0, "Divine Protection prevented 15")
			C.eq(RS.effective_healing(), 53, "effective healing = 20 + 18 + 15")
			cast("renew", T[3]); cast("overgrowth", T[3])
			T[1].health_comp.current_health = 10.0
			BS.try_bandage(T[1]); wait = 2.6
		4:
			P("combos=%d (Overgrowth) bandages=%d effective now=%d (bandage +40, Renew ticks while not full)" % [RS.combos, RS.bandages, RS.effective_healing()])
			C.eq(RS.combos, 1, "Overgrowth on Renew counts one combo")
			C.eq(RS.bandages, 1, "one bandage counted")
			C.ok(RS.effective_healing() > 53 + 30, "the bandage and Renew ticks add effective healing")
			GM.current_round = 7
			T[0].health_comp.take_damage(99999); wait = 0.3
		5:
			P("game over: '%s'" % game.final_score_label.text.replace("\n", " / "))
			P("leaderboard payload: %s · best line: '%s'" % [str(game._last_run), game.score_label.text])
			C.ok(game.game_over_panel.visible, "death shows the game over panel")
			C.eq(game._last_run.rounds, GM.rounds_survived(), "payload rounds = rounds survived")
			C.eq(game._last_run.healing, RS.effective_healing(), "payload healing = effective healing")
			game._show_leaderboard(true, [{"name": "Marz", "rounds": 7, "healing": 5050}, {"name": "Ann", "rounds": 7, "healing": 980}])
			wait = 0.05
		6:
			P("leaderboard rows: %s" % str(game.lb_grid.get_children().filter(func(c): return not c.is_queued_for_deletion()).map(func(c): return c.text)))
			var rows: Array = game.lb_grid.get_children().filter(func(c): return not c.is_queued_for_deletion()).map(func(c): return c.text)
			C.ok("Marz" in rows and "Ann" in rows, "leaderboard rows show both names")
			var lb = root.get_node("Leaderboard")
			C.ok(lb._parse(0, 200, "<html>host error</html>".to_utf8_buffer()) == null, "a non-JSON server reply is ignored (quietly: no ERROR line)")
			C.done(self)
	step += 1
	return false
