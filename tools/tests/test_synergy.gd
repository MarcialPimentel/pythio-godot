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
			# Tag-weighted offers (#68): share of offered new cards that share/react to a tag you own
			var share_for := func(w: float) -> float:
				DS.tag_affinity_weight = w
				var hit := 0; var n := 0
				for i in 600:
					DS.tag_affinity_weight = w
					var offers: Array = DS.make_offers()
					DS.tag_affinity_weight = 1.0   # measure with weighting on, whatever made the offer
					for c in offers:
						if SS.owned_rank(c.family()) > 0: continue
						n += 1
						if DS.tag_affinity(c) > 1.0: hit += 1
				return float(hit) / maxf(1.0, n)
			var off: float = share_for.call(0.0); var on: float = share_for.call(1.0)
			P("RESULT tag-weighted offers: cards touching your tags %.0f%% with weighting off → %.0f%% on (higher=%s)" % [off * 100.0, on * 100.0, on > off])
			P("affinity: Overgrowth=%.1f Mend Wounds=%.1f Spirit Surge=%.1f (Renew + Overgrowth owned: HoT)" % [DS.tag_affinity(SS.get_library_spell("overgrowth")), DS.tag_affinity(SS.get_library_spell("mend_wounds")), DS.tag_affinity(SS.get_library_spell("spirit_surge"))])
			SS.add_spell(SS.get_library_spell("shield"))
			# The build summary line above the bar was removed (owner, 2026-10-24).
			P("RESULT no build summary label: %s" % (not "_build_label" in game))
			quit()
	step += 1
	return false
