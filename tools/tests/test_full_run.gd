extends SceneTree
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
	f += 1
	if f == 3:
		GM = root.get_node("GameManager"); DS = root.get_node("DifficultySystem"); TS = root.get_node("TargetSystem")
		DS.base_dps = 0.0; DS.dps_growth = 0.0
		P("endless=%s round times 1..12 = %s" % [DS.is_endless(), range(1, 13).map(func(r): return DS.get_round_time(r))])
		game._on_start_pressed()
		Engine.time_scale = 30.0
	if f > 3 and not played_again and game.party_choice_panel.visible and not GM.in_round and not game.game_over_panel.visible:
		var contracts = game.contract_selector.get_contracts_for_round(GM.current_round)
		P("round %d starts: round_time=%.1f mana=%.1f/%.1f boss=%s choices=%d name='%s'" % [GM.current_round, GM.round_time, GM.mana, GM.max_mana, contracts[0].is_boss, contracts.size(), contracts[0].contract_name])
		game.party_choice_panel._on_left_chosen()
	if f > 3 and GM.in_round and GM.current_round == STOP_AT and not killed:
		killed = true
		var t = TS.targets[0]
		t.health_comp.take_damage(99999.0)
	if game.game_over_panel.visible and not played_again:
		played_again = true
		P("game over shown: '%s'" % game.final_score_label.text.replace("\n", " / "))
		game.play_again_button.emit_signal("pressed")
	if played_again and not game.game_over_panel.visible and GM.current_round == 1:
		P("after Play Again: round=%d game_over_visible=%s score=%d" % [GM.current_round, game.game_over_panel.visible, GM.score])
		quit()
	if f > 40000: P("TIMEOUT"); quit()
	return false
