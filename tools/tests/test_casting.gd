extends SceneTree
var game; var GM; var TS; var SS; var step := 0; var wait := 0.0; var t0; var t1
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func key(k):
	var e := InputEventKey.new(); e.physical_keycode = k; e.keycode = k; e.pressed = true
	Input.parse_input_event(e)
	var u := InputEventKey.new(); u.physical_keycode = k; u.keycode = k; u.pressed = false
	Input.parse_input_event(u)
func hp(t): return t.health_comp.current_health
func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	wait -= d
	if wait > 0: return false
	match step:
		0:
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); SS = root.get_node("SpellSystem")
			root.get_node("DifficultySystem").base_dps = 0.0   # isolate healing from damage for the test
			game._on_start_pressed(); wait = 0.7
		1:
			# Flash Heal (instant), Mend Wounds (1s cast + heal-over-time), Shield (instant)
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "mend_wounds", "shield"]))
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			t0 = TS.targets[0]; t1 = TS.targets[1]
			P("spell keys on buttons: %s | mana bar visible=%s text='%s'" % [game.spell_buttons.map(func(b): return b.get_node("Key").text), game.mana_bar.visible, game.mana_label.text])
			P("bars: hp_bar max=%.0f (fighter max %.0f)" % [t0.hp_bar.max_value, t0.health_comp.max_health])
			t0.health_comp.current_health = 40
			P("[click] select Flash Heal, click fighter 0 | before hp=%.0f mana=%.0f" % [hp(t0), GM.mana])
			game.spell_buttons[0].emit_signal("pressed"); t0.target_button.emit_signal("pressed"); wait = 0.05
		3:
			P("[click] after: hp=%.0f mana=%.0f hp_bar=%.0f" % [hp(t0), GM.mana, t0.hp_bar.value])
			t1.health_comp.current_health = 30
			t1.target_button.emit_signal("mouse_entered")
			P("[hover W] Mend Wounds on fighter 1 | before hp=%.0f mana=%.0f" % [hp(t1), GM.mana])
			key(KEY_W); wait = 0.2
		4:
			P("[hover W] mid-cast: casting=%s cast_bar visible=%s label='%s' value=%.0f" % [SS.is_casting, game.cast_bar.visible, game.cast_label.text, game.cast_bar.value])
			wait = 1.0
		5:
			P("[hover W] after cast: casting=%s cast_bar visible=%s hot_time=%.1f mana=%.0f" % [SS.is_casting, game.cast_bar.visible, t1.health_comp.hot_time, GM.mana])
			wait = 2.0
		6:
			P("[hover W] 2s of Mend Wounds HoT ticking: hp=%.1f" % hp(t1))
			key(KEY_E); wait = 0.05
		7:
			P("[hover E] Shield: shield=%.0f shield_bar=%.0f mana=%.0f" % [t1.health_comp.shield_amount, t1.shield_bar.value, GM.mana])
			t1.target_button.emit_signal("mouse_exited")
			GM.mana = 5.0; var before = hp(t0)
			game.spell_buttons[0].emit_signal("pressed"); t0.target_button.emit_signal("pressed"); wait = 0.05
			P("[no mana] Flash Heal with 5 mana: button disabled=%s" % game.spell_buttons[0].disabled)
		8:
			P("[no mana] hp=%.0f (unchanged expected) mana=%.0f" % [hp(t0), GM.mana])
			GM.mana = 100.0
			t0.target_button.emit_signal("mouse_entered"); key(KEY_W); wait = 0.2
		9:
			P("[round end mid-cast] casting=%s → forcing round end" % SS.is_casting)
			GM.round_time = 0.0; wait = 0.1
		10:
			P("[round end mid-cast] casting=%s cast_bar visible=%s mana=%.0f (no Mend Wounds charged)" % [SS.is_casting, game.cast_bar.visible, GM.mana])
			quit()
	step += 1
	return false
