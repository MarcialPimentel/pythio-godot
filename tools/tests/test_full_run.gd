extends SceneTree
var game; var f := 0; var GM; var DS; var times := []; var played_again := false; var t0 := 0.0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func _process(d):
	f += 1
	if f == 3:
		GM = root.get_node("GameManager"); DS = root.get_node("DifficultySystem"); DS.base_dps = 0.0; DS.dps_growth = 0.0
		P("round times 1..6 = %s" % [range(1,7).map(func(r): return DS.get_round_time(r))])
		game._on_start_pressed()
		Engine.time_scale = 30.0
	if f > 3 and game.party_choice_panel.visible and not GM.in_round and not game.game_over_panel.visible:
		P("round %d starts: round_time=%.1f mana=%.1f/%.1f" % [GM.current_round, GM.round_time, GM.mana, GM.max_mana])
		GM.mana = 10.0 if GM.current_round == 2 else GM.mana
		game.party_choice_panel._on_left_chosen()
	if game.game_over_panel.visible and not played_again:
		played_again = true
		P("game over shown: '%s' | start-screen label: '%s' | button text: '%s'" % [game.final_score_label.text.replace("\n"," / "), game.score_label.text, game.play_again_button.text])
		game.play_again_button.emit_signal("pressed")
	if played_again and f % 10 == 0 and game.party_choice_panel.visible:
		P("after Play Again: round=%d panel_visible=%s game_over_visible=%s score=%d" % [GM.current_round, game.party_choice_panel.visible, game.game_over_panel.visible, GM.score])
		quit()
	if f > 20000: P("TIMEOUT"); quit()
	return false
