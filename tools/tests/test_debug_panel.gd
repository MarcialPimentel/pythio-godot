extends SceneTree
# Debug panel (F1): toggle, jump to round, +mana, god mode, hit/heal, skip round,
# and that a debug run can't be posted to the leaderboard. Play Again starts clean.
var game; var f := 0; var GM; var TS; var dbg; var step := 0; var wait := 0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func press(key: Key):
	var e := InputEventKey.new(); e.keycode = key; e.pressed = true
	root.push_input(e)
func _process(_d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	if wait > 0:
		wait -= 1; return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem")
			for c in game.get_children():
				if c is CanvasLayer and c.has_method("_toggle_god"): dbg = c
			P("panel found=%s hidden at start=%s" % [dbg != null, not dbg._panel.visible])
			game._on_start_pressed(); press(KEY_F1); step = 1; wait = 60
		1:
			if root.get_node("DraftSystem").current_spec == null: return false
			P("F1 opens panel: %s" % dbg._panel.visible)
			dbg._round_spin.value = 15; dbg._jump(); step = 2; wait = 2
		2:
			var c = game.contract_selector.get_contracts_for_round(GM.current_round)
			P("after jump: round=%d mana=%d/%d boss=%s debug_used=%s" % [GM.current_round, GM.mana, GM.max_mana, c[0].is_boss, GM.debug_used])
			game.party_choice_panel._on_left_chosen(); step = 3; wait = 3
		3:
			GM.mana = 10.0; dbg._add_mana(); P("+50 mana: %d" % GM.mana)
			dbg._toggle_god(); dbg._target = TS.targets[0]
			for i in 20: dbg._hit_target()
			var hc = TS.targets[0].health_comp
			P("god mode, 20 hits of 25: hp=%.0f/%.0f dead=%s in_round=%s" % [hc.current_health, hc.max_health, hc.is_dead, GM.in_round])
			dbg._heal_target(); P("heal to full: hp=%.0f" % hc.current_health)
			dbg._skip_round(); step = 4; wait = 3
		4:
			if not game.party_choice_panel.visible or game.card_panel.visible: return false
			P("skip round: now round=%d in_round=%s (round 15 was a pick round: spell picked=%s)" % [GM.current_round, GM.in_round, root.get_node("SpellSystem").spells.size() > 1])
			game.party_choice_panel._on_left_chosen(); step = 5; wait = 3
		5:
			dbg._toggle_god(); dbg._target = TS.targets[0]
			for i in 40: dbg._hit_target()
			step = 6; wait = 3
		6:
			P("game over visible=%s submit disabled=%s status='%s'" % [game.game_over_panel.visible, game.submit_button.disabled, game.submit_status.text])
			game.play_again_button.emit_signal("pressed"); step = 7; wait = 5
		7:
			P("Play Again: round=%d debug_used=%s god_mode=%s" % [GM.current_round, GM.debug_used, GM.god_mode])
			quit()
	if f > 5000: P("TIMEOUT"); quit()
	return false
