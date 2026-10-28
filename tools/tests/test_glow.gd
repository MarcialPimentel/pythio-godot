extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Combo-ready glow: a spell button glows gold when casting it on the hovered fighter would
# fire a combo — Overgrowth on a HoT, Spirit Surge on a Shield, Direct heals on an
# Echo-marked fighter, Direct heals on a low fighter with Seraphic Blessing.
var game; var f := 0; var GM; var SS; var TS; var step := 0; var wait := 0.0; var T := []
var shot := ""
func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: shot = a[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func cast(id: String, t): SS.cooldowns.clear(); SS.request_cast(SS.get_library_spell(id), t)
func glowing() -> Array:
	var out := []
	for i in game.spell_buttons.size():
		if game.spell_buttons[i].get_node("Glow").visible: out.append(SS.spells[i].id)
	return out
func hover(t):
	for x in T: x.target_button.emit_signal("mouse_exited")
	t.target_button.emit_signal("mouse_entered")

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(1)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			var DS = root.get_node("DifficultySystem"); DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			SS.set_spellbook_ids(PackedStringArray(["renew", "overgrowth", "heal", "spirit_surge", "echo_healing", "seraphic_blessing"]))
			GM.mana = 999.0; GM.max_mana = 999.0
			for t in T: t.health_comp.current_health = t.health_comp.max_health * 0.8
			hover(T[0]); wait = 0.1
		3:
			P("hover a fighter with nothing on them: glowing=%s (none)" % str(glowing()))
			cast("renew", T[0]); wait = 0.1
		4:
			P("after Renew on them: glowing=%s (overgrowth)" % str(glowing()))
			T[1].health_comp.apply_shield(20, 8); hover(T[1]); wait = 0.1
		5:
			P("hover a shielded fighter: glowing=%s (spirit_surge)" % str(glowing()))
			cast("echo_healing", T[2]); hover(T[2]); wait = 0.1
		6:
			P("hover an Echo-marked fighter: glowing=%s (heal, spirit_surge? no shield → heal only)" % str(glowing()))
			T[3].health_comp.current_health = T[3].health_comp.max_health * 0.25; hover(T[3]); wait = 0.1
		7:
			P("hover a fighter at 25%% with Seraphic Blessing: glowing=%s (heal)" % str(glowing()))
			GM.mana = 0.0; wait = 0.1
		8:
			P("same, but no mana to cast: glowing=%s (none — glow means 'press it now')" % str(glowing()))
			GM.mana = 999.0; hover(T[0]); wait = 0.15
		9:
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot); print("saved shot")
			C.done(self)
	step += 1
	return false
