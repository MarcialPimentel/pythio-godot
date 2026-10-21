extends SceneTree
# Synergy hints on pick cards, the "at least one offer combos with your spellbook" rule,
# and the build summary above the spell bar.
var game; var f := 0; var DS; var SS; var step := 0; var wait := 0.0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func strip(bb: String) -> String:
	var r := RegEx.new(); r.compile("\\[[^\\]]*\\]")
	return r.sub(bb, "", true).replace("\n", " | ")

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			DS = root.get_node("DraftSystem"); SS = root.get_node("SpellSystem")
			game._on_start_pressed(); wait = 0.2
		1:
			game.card_panel._choose(1); wait = 0.6   # Bloom → Renew
		2:
			for id in ["overgrowth", "aura_of_mending", "healing_plague", "mend_wounds", "spirit_surge", "flash_heal"]:
				P("hint for %-16s %s" % [id + ":", strip(game.synergy_hint_bb(SS.get_library_spell(id)))])
			SS.add_spell(SS.get_library_spell("overgrowth"))
			P("after taking Overgrowth, hint for Mend Wounds: %s" % strip(game.synergy_hint_bb(SS.get_library_spell("mend_wounds"))))
			var with_syn := 0
			for i in 300:
				if DS.make_offers().any(DS.has_synergy): with_syn += 1
			P("RESULT offers with at least one combo card: %d / 300" % with_syn)
			SS.add_spell(SS.get_library_spell("shield"))
			P("build summary: '%s'" % strip(game._build_label.text))
			quit()
	step += 1
	return false
