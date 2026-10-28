extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Endless run: plays rounds 1–12 with damage off (fast-forwarded), checks round lengths,
# that the Crimson Baron appears on every 5th round, mana top-up, then kills a fighter
# in round 12 to check the game-over screen and Play Again.
var game; var f := 0; var GM; var DS; var TS; var played_again := false; var killed := false
const STOP_AT := 12
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	if f == 3:
		GM = root.get_node("GameManager"); DS = root.get_node("DifficultySystem"); TS = root.get_node("TargetSystem")
		DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_damage_base = 0.0; DS.burst_damage_growth = 0.0
		DS.debuff_start_round = 9999   # no Poison/Bleed: only the scripted death may end this run
		var BD = root.get_node("BossDirector")
		BD.bleed_per_second = 0.0; BD.bleed_per_second_phase_3 = 0.0; BD.assassin_hit = 0.0; BD.execution_hit = 0.0
		P("round times 1..12 = %s" % [range(1, 13).map(func(r): return DS.get_round_time(r))])
		C.eq(range(1, 13).map(func(r): return DS.get_round_time(r)), [15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 25.0], "round lengths: 15s + 1s a round, capped at 25s")
		game._on_start_pressed()
		Engine.time_scale = 30.0
	if f > 3 and not played_again and game.party_choice_panel.visible and not GM.in_round and not game.game_over_panel.visible:
		var contracts = game.contract_selector.get_contracts_for_round(GM.current_round)
		P("round %d starts: round_time=%.1f mana=%.1f/%.1f boss=%s choices=%d name='%s'" % [GM.current_round, GM.round_time, GM.mana, GM.max_mana, contracts[0].is_boss, contracts.size(), contracts[0].contract_name])
		C.eq(contracts[0].is_boss, GM.current_round % 5 == 0, "round %d: Baron only on every 5th round" % GM.current_round); C.near(GM.round_time, DS.get_round_time(GM.current_round), "round %d length" % GM.current_round)
		game.party_choice_panel._on_left_chosen()
	if f > 3 and GM.in_round and GM.current_round == STOP_AT and not killed:
		killed = true
		var t = TS.targets[0]
		t.health_comp.take_damage(99999.0)
	if game.game_over_panel.visible and not played_again:
		played_again = true
		P("game over shown: '%s'" % game.final_score_label.text.replace("\n", " / "))
		C.eq(GM.current_round, STOP_AT, "the run reached round %d" % STOP_AT)
		game.play_again_button.emit_signal("pressed")
	if played_again and not game.game_over_panel.visible and GM.current_round == 1:
		P("after Play Again: round=%d game_over_visible=%s" % [GM.current_round, game.game_over_panel.visible])
		C.ok(not game.game_over_panel.visible, "Play Again hides the game over panel")
		C.done(self)
	if f > 40000: C.timed_out(self)
	return false
