extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Debug panel (F1): toggle, jump to round, +mana, god mode, hit/heal, skip round,
# and that a debug run can't be posted to the leaderboard. Play Again starts clean.
var game; var f := 0; var GM; var TS; var dbg; var step := 0; var wait := 0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func DraftSystemNode(): return root.get_node("DraftSystem")
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
			C.ok(dbg._panel.visible, "F1 opens the debug panel")
			dbg._round_spin.value = 15; dbg._jump(); step = 2; wait = 2
		2:
			var c = game.contract_selector.get_contracts_for_round(GM.current_round)
			P("after jump: round=%d mana=%d/%d boss=%s debug_used=%s" % [GM.current_round, GM.mana, GM.max_mana, c[0].is_boss, GM.debug_used])
			C.ok(GM.debug_used, "using the debug panel marks the run as debug")
			game.party_choice_panel._on_left_chosen(); step = 3; wait = 3
		3:
			GM.mana = 10.0; dbg._add_mana(); P("+50 mana: %d" % GM.mana)
			# Take any spell (#69)
			var SSn = root.get_node("SpellSystem")
			P("take-any list: %d entries, first='%s'" % [dbg._spell_pick.item_count, dbg._spell_pick.get_item_text(0)])
			for id in ["lifebloom", "overgrowth", "renew", "spirit_surge", "bulwark"]:
				dbg._spell_pick.select(dbg._spell_ids.find(id)); dbg._take_spell()
			P("RESULT took Lifebloom, Overgrowth, Renew, Spirit Surge (bar full → replaced the last slot), Bulwark: spells=%s passives=%s" % [SSn.spells.map(func(x): return x.id), SSn.passives.map(func(x): return x.id)])
			dbg._spell_pick.select(dbg._spell_ids.find("rejuvenation")); dbg._take_spell()
			P("took Rejuvenation (Renew already swapped out, bar full → replaces the last slot): %s" % [SSn.spells.map(func(x): return x.id)])
			DraftSystemNode().debug_reset_build()
			P("reset build: %s" % [SSn.spells.map(func(x): return x.id)])
			dbg._toggle_god(); dbg._target = TS.targets[0]
			for i in 20: dbg._hit_target()
			var hc = TS.targets[0].health_comp
			P("god mode, 20 hits of 25: hp=%.0f/%.0f dead=%s in_round=%s" % [hc.current_health, hc.max_health, hc.is_dead, GM.in_round])
			C.ok(not hc.is_dead, "god mode: nobody dies")
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
			C.ok(game.game_over_panel.visible and game.submit_button.disabled, "a debug run can't be posted")
			game.play_again_button.emit_signal("pressed"); step = 7; wait = 5
		7:
			P("Play Again: round=%d debug_used=%s god_mode=%s" % [GM.current_round, GM.debug_used, GM.god_mode])
			C.eq(GM.current_round, 1, "Play Again starts at round 1"); C.ok(not GM.debug_used and not GM.god_mode, "Play Again starts a clean, postable run")
			C.done(self)
	if f > 5000: C.timed_out(self)
	return false
