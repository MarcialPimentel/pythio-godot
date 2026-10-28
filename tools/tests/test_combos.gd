extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Combo spells with real casts: Renew → Overgrowth, Echo Healing → Heal, Shield → Spirit Surge.
# Checks the gold combo label on the fighter, Pythio's quip, and that combo spells are only
# offered once you own a spell with the tag they react to.
var game; var f := 0; var GM; var DS; var SS; var TS; var step := 0; var wait := 0.0
var combos := []; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func cast(id: String, t): SS.request_cast(SS.get_library_spell(id), t)
func gold_labels(t) -> Array:
	return t.fx_layer.get_children().filter(func(c): return c is Label and c.get_theme_color("font_color").is_equal_approx(Color(1.0, 0.82, 0.3))).map(func(c): return c.text)

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); DS = root.get_node("DraftSystem"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.8
		1:
			# Mending start (Heal). Combo spells gated on tags:
			var gate := func(id): return DS.requirements_met(SS.get_library_spell(id))
			P("as Mending (Heal = Direct): Overgrowth offered=%s · Echo Healing offered=%s · Spirit Surge offered=%s" % [gate.call("overgrowth"), gate.call("echo_healing"), gate.call("spirit_surge")])
			SS.set_spellbook_ids(PackedStringArray(["renew", "overgrowth", "heal", "echo_healing", "shield"]))
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			for t in T: t.health_comp.current_health = 10.0
			GM.mana = 999.0
			cast("renew", T[0]); wait = 0.1
		3:
			var before: float = T[0].health_comp.hot_time
			cast("overgrowth", T[0]); wait = 0.1
			P("Overgrowth on Renew: HoT %.1fs → %.1fs · combos=%s · gold text=%s" % [before, T[0].health_comp.hot_time, combos, gold_labels(T[0])])
		4:
			combos.clear()
			cast("echo_healing", T[1]); wait = 0.1
		5:
			cast("heal", T[1]); wait = 1.7   # 1.5s cast
		6:
			P("Echo + Heal: hp right after Heal=%.0f (40) combos=%s gold=%s" % [hp(T[1]), combos, gold_labels(T[1])])
			wait = 2.1
		7:
			P("Echo 2s later: hp=%.0f (55)" % hp(T[1]))
			SS.set_spellbook_ids(PackedStringArray(["shield", "spirit_surge"]))
			combos.clear(); GM.mana = 999.0
			cast("shield", T[2]); wait = 0.1
		8:
			cast("spirit_surge", T[2]); wait = 0.1
		9:
			P("Shield → Spirit Surge: hp=%.0f (10+45, capped at max HP) shield=%.0f combos=%s" % [hp(T[2]), T[2].health_comp.shield_amount, combos])
			P("Pythio quip visible=%s text='%s'" % [game.quip_bubble.visible, game.quip_label.text])
			P("card text: %s" % str(["overgrowth", "echo_healing", "spirit_surge"].map(func(id): return SS.get_library_spell(id).description_plain())))
			C.done(self)
	step += 1
	return false
