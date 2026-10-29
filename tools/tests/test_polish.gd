extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Steam polish, step 1 (docs/art-direction.md): the window fills any screen shape, the
# portrait is gone, card screens don't show a second title behind theirs, no on-screen text is
# under 18 px, and the HUD stays on its edges on an ultrawide screen.
var game; var f := 0; var step := 0; var wait := 0.0
var GM; var TS; var SS; var DS
var SF   # ui/ScreenFeel.gd, loaded by path once the autoloads exist (tools/tests/README.md)
var reduce_before := false
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)

## Every visible label under `node` smaller than the floor (skips the F1 debug panel).
func small_text(node: Node, out: Array) -> Array:
	if node is CanvasItem and not node.is_visible_in_tree():
		return out
	if node.get_script() and node.get_script().resource_path.ends_with("DebugPanel.gd"):
		return out
	if node is Label and node.text.strip_edges() != "":
		var sz: int = node.get_theme_font_size("font_size")
		if sz < 18: out.append("%s '%s' %dpx" % [node.name, node.text.left(24), sz])
	elif node is RichTextLabel and node.get_parsed_text().strip_edges() != "":
		var sz: int = node.get_theme_font_size("normal_font_size")
		if sz < 18: out.append("%s '%s' %dpx" % [node.name, node.get_parsed_text().left(24), sz])
	for c in node.get_children():
		small_text(c, out)
	return out

func EventBus_emit_hit():
	root.get_node("EventBus").burst_landed.emit(TS.targets[2], 0.0, 20.0)

func advance() -> bool:
	step = 100
	return false

func _process(d):
	f += 1
	if f > 3000: C.timed_out(self); return true
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			SF = load("res://ui/ScreenFeel.gd")
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); SS = root.get_node("SpellSystem"); DS = root.get_node("DifficultySystem")
			DS.job_finished_time = 0.0; DS.screen_input_guard = 0.0
			C.eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "window scales the interface (no fixed 1920x1080 picture)")
			C.eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "window fills any screen shape (no black bars)")
			C.ok(game.get_node_or_null("GameUI/Portrait") == null and game.get_node_or_null("GameUI/PortraitName") == null, "the bottom-right portrait is gone")
			var small: Array = small_text(game.start_screen, [])
			P("title screen small text: %s" % [small])
			C.eq(small.size(), 0, "title screen: no text under 18 px")
			game._on_start_pressed(); wait = 0.3
		1:
			if not game.card_panel.visible or game.card_panel._locked: return false
			P("spell choice: header visible=%s, card title='%s'" % [game.header.visible, game.card_panel._title.text])
			C.ok(game.card_panel.visible and not game.header.visible, "Choose your spell: only the card screen's title shows")
			var small: Array = small_text(game.game_ui, [])
			P("spell choice small text: %s" % [small])
			C.eq(small.size(), 0, "spell choice cards: no text under 18 px")
			game.card_panel._choose(0); wait = 0.3
		2:
			if not game.party_choice_panel.visible: return false
			P("next party: header visible=%s round='%s' sub='%s'" % [game.header.visible, game.round_label.text, game.timer_label.text])
			C.ok(game.party_choice_panel.visible and game.header.visible and game.round_label.text == "Round 1", "Next party shows the round number")
			C.eq(game.timer_label.text, "", "no 'Get ready' line running into 'Next party'")
			DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			SS.set_spellbook_ids(PackedStringArray(["heal", "renew", "shield", "aura_of_mending"]))
			game.party_choice_panel._on_left_chosen(); wait = 0.5
		3:
			if not GM.in_round or TS.targets.is_empty(): return false
			C.ok(game.header.visible, "in the round the header is back")
			GM.mana = 999.0
			SS.request_cast(SS.get_library_spell("renew"), TS.targets[0])
			SS.request_cast(SS.get_library_spell("shield"), TS.targets[1])
			wait = 0.3
		4:
			var small: Array = small_text(game.game_ui, [])
			P("round small text: %s" % [small])
			C.eq(small.size(), 0, "combat screen: no text under 18 px (spell names, passive names, rules, armour)")
			# Step 2, feel: fighters stand on a shadow; a shield puffs blue sparks.
			C.ok(TS.targets.all(func(t): return t.get_node_or_null("GroundShadow") != null), "every fighter has a ground shadow")
			C.ok(TS.targets[1].fx_layer.get_children().any(func(c): return c is CPUParticles2D), "a shield puffs sparks on the fighter")
			reduce_before = SF.reduce_effects
			SF.set_reduce(false)
			EventBus_emit_hit(); return advance()
		100:
			P("burst hit: screen offset=%s" % game.game_ui.position)
			C.ok(game.game_ui.position != Vector2.ZERO, "a landed burst shakes the screen")
			root.get_node("EventBus").combo_fired.emit(TS.targets[0], "Test combo")
			C.ok(game.game_ui.scale.x > 1.0, "a combo punches the screen in")
			step = 101; wait = 0.7; return false
		101:
			C.eq(game.game_ui.position, Vector2.ZERO, "the shake settles back to rest")
			C.eq(game.game_ui.scale, Vector2.ONE, "the punch settles back to rest")
			SF.set_reduce(true)
			EventBus_emit_hit()
			root.get_node("EventBus").combo_fired.emit(TS.targets[0], "Test combo")
			step = 102; return false
		102:
			C.ok(game.game_ui.position == Vector2.ZERO and game.game_ui.scale == Vector2.ONE, "reduce effects: no shake, no punch")
			var menu = game.get_children().filter(func(c): return c.get_script() and c.get_script().resource_path.ends_with("PauseMenu.gd"))[0]
			var box = menu.find_child("ReduceEffects", true, false)
			C.ok(box is CheckBox, "pause menu has 'Reduce screen shake and flashes'")
			box.button_pressed = true
			C.ok(SF.reduce_effects, "ticking it turns them off")
			box.button_pressed = false
			C.ok(not SF.reduce_effects, "unticking it turns the effects back on")
			SF.set_reduce(reduce_before)
			step = 4
			# An ultrawide window: the spell bar stays centred, the rules stay top right.
			root.size = Vector2i(2560, 1080)
			wait = 0.3
		5:
			var vis: Vector2 = root.get_visible_rect().size
			var bar: Rect2 = game.spell_container.get_global_rect()
			var rules: Rect2 = game.hud.rules_box.get_global_rect()
			var pythio: Rect2 = game.pythio_sprite.get_global_rect()
			P("ultrawide: visible=%s spell bar centre=%.0f rules right=%.0f pythio bottom=%.0f party x=%.0f..%.0f" % [vis, bar.get_center().x, rules.end.x, pythio.end.y,
				game.party_area.position.x, game.party_area.position.x + game.party_area.size.x * game.party_area.scale.x])
			C.ok(vis.x > 2000.0, "the visible area widened (got %.0f)" % vis.x)
			C.near(bar.get_center().x, vis.x / 2.0, "spell bar centred on a wide screen", 4.0)
			C.near(rules.end.x, vis.x - 20.0, "battlefield rules pinned to the right edge", 4.0)
			C.near(game.party_area.position.x + game.party_area.size.x * game.party_area.scale.x / 2.0, vis.x / 2.0, "party centred on a wide screen", 4.0)
			# Steam Deck shape (16:10): taller, HUD still on the bottom edge.
			root.size = Vector2i(1280, 800)
			wait = 0.3
		6:
			var vis: Vector2 = root.get_visible_rect().size
			var bar: Rect2 = game.spell_container.get_global_rect()
			var pythio: Rect2 = game.pythio_sprite.get_global_rect()
			P("16:10: visible=%s spell bar bottom=%.0f pythio bottom=%.0f" % [vis, bar.end.y, pythio.end.y])
			C.ok(vis.y > 1150.0, "the visible area got taller on 16:10 (got %.0f)" % vis.y)
			C.near(vis.y - bar.end.y, 1080.0 - 990.0, "spell bar keeps its distance from the bottom edge", 4.0)
			C.near(vis.y - pythio.end.y, 1080.0 - 1075.0, "Pythio stands on the bottom edge", 4.0)
			root.size = Vector2i(1920, 1080)
			TS.targets[2].health_comp.take_damage(99999)
			wait = 1.2
		7:
			var veil: ColorRect = game.game_ui.get_node("DeathVeil")
			P("death: veil visible=%s alpha=%.2f, under game over=%s" % [veil.visible, veil.color.a, veil.get_index() < game.game_over_panel.get_index()])
			C.ok(veil.visible and veil.color.a > 0.3, "a death darkens the battlefield")
			C.ok(veil.get_index() < game.game_over_panel.get_index(), "the run summary stays bright above the veil")
			game._on_play_again_pressed(); wait = 0.5
		8:
			var veil: ColorRect = game.game_ui.get_node("DeathVeil")
			C.ok(not veil.visible and veil.color.a == 0.0, "Play Again clears the veil")
			C.done(self); return true
	step += 1
	return false
