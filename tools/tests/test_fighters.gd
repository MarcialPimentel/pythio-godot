extends SceneTree
var game; var GM; var TS; var CG; var step := 0; var wait := 0.0; var deaths := 0; var snap := {}
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	wait -= d
	if wait > 0: return false
	match step:
		0:
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); CG = root.get_node("ContractGenerator")
			var counts := {}; var chars := {}
			for r in [1,3]:
				for i in 200:
					for t in CG.generate_contract(r).unit_templates:
						counts[t.armor_type] = counts.get(t.armor_type, 0) + 1
						chars[t.character] = chars.get(t.character, 0) + 1
			P("armor rolls over 400 contracts: %s" % counts)
			P("characters: %s" % chars)
			var c1 = CG.generate_contract(1); var c3 = CG.generate_contract(3)
			P("round1 units: %s" % [c1.unit_templates.map(func(t): return "%s/%s/%dHP" % [t.display_name, t.armor_type, t.base_max_health])])
			P("round3 units: %s" % [c3.unit_templates.map(func(t): return "%s/%s/%dHP" % [t.display_name, t.armor_type, t.base_max_health])])
			var b = CG.generate_boss_contract(5).unit_templates[0]
			P("boss: %s %s %dHP" % [b.display_name, b.character, b.base_max_health])
			game._on_start_pressed(); wait = 0.7
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			for t in TS.targets: snap[t] = t.health_comp.current_health
			wait = 1.0
		3:
			P("damage taken in ~1s by armor: %s" % [TS.targets.map(func(t): return "%s %.1f" % [t.armor_type, snap[t] - t.health_comp.current_health])])
			P("names on frames: %s" % [TS.targets.map(func(t): return t.target_name.text)])
			for t in TS.targets: t.health_comp.died.connect(func(): deaths += 1)
			TS.targets[0].health_comp.current_health = 0.5
			wait = 0.5
		4:
			P("after fighter 0 drops: died signals=%d in_round=%s game_over_visible=%s party_visible=%s" % [deaths, GM.in_round, game.game_over_panel.visible, game.party_container.visible])
			P("game over text: '%s'" % game.final_score_label.text.replace("\n"," / "))
			P("fallen frame: '%s'" % TS.targets[0].target_name.text)
			TS.targets[0].health_comp.heal(50)
			P("heal on fallen fighter ignored: hp=%.1f" % TS.targets[0].health_comp.current_health)
			game.play_again_button.emit_signal("pressed"); wait = 0.8
		5:
			P("play again: round=%d choice_visible=%s game_over_visible=%s" % [GM.current_round, game.party_choice_panel.visible, game.game_over_panel.visible])
			quit()
	step += 1
	return false
