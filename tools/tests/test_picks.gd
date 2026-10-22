extends SceneTree
# Specialization pick and spell picks: schedule, offer rules, rank-ups, cap, build complete,
# and the real flow (school pick → round 1 → spell pick → contracts).
var game; var f := 0; var GM; var DS; var SS; var step := 0; var wait := 0.0; var complete := 0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func ids(list): return list.map(func(s): return s.id if s is SpellData else str(s))

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); DS = root.get_node("DraftSystem"); SS = root.get_node("SpellSystem")
			DS.build_complete.connect(func(): complete += 1)
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			game._on_start_pressed(); wait = 0.2
		1:
			P("school screen: visible=%s mode=%s schools=%s spellbook=%s" % [game.card_panel.visible, game._card_mode, DS.specs.map(func(s): return s.display_name), ids(SS.spells)])
			game.card_panel._choose(1); wait = 0.6   # Bloom
		2:
			P("picked %s: spellbook=%s contract screen=%s" % [DS.current_spec.display_name, ids(SS.spells), game.party_choice_panel.visible])
			P("pick rounds 1..21: %s" % [range(1, 22).filter(func(r): return DS.is_pick_round(r))])
			# Offer rules over many rolls
			var counts := {"own": 0, "any": 0, "other": 0, "upgrade": 0, "dupes": 0, "owned": 0, "with_other": 0, "rolls": 300}
			for i in 300:
				var o: Array = DS.make_offers()
				var seen := {}
				var had_other := false
				for s in o:
					if seen.has(s.id): counts.dupes += 1
					seen[s.id] = true
					if SS.spells.has(s): counts.owned += 1
					if SS.owned_rank(s.family()) > 0: counts.upgrade += 1
					elif s.school == "BLOOM": counts.own += 1
					elif s.school == "ANY": counts.any += 1
					else: counts.other += 1; had_other = true
				if had_other: counts.with_other += 1
			P("300 offer rolls as Bloom (Renew owned): %s" % counts)
			P("RESULT offers have no duplicates or owned spells=%s, one other-school card each time=%s" % [counts.dupes == 0 and counts.owned == 0, counts.with_other == 300])
			var gated: Array = SS.library.filter(func(s): return not s.requires_tags.is_empty())
			P("spells that need a tag you own: %s" % [gated.map(func(s): return "%s needs %s → offered now=%s" % [s.id, s.requires_tags, DS.requirements_met(s)])])
			# Rank-up replaces in the same slot
			SS.add_spell(SS.get_library_spell("shield"))
			var slot = SS.add_spell(SS.get_library_spell("rejuvenation"))
			P("rank-up: Rejuvenation went to slot %d, spellbook=%s" % [slot, ids(SS.spells)])
			# Fill to the cap (the old rule: no swaps, so a full row only gets rank-ups; test_swap.gd covers swaps)
			DS.swap_when_full = false
			for id in ["heal", "lifebloom", "chain_heal"]:
				SS.add_spell(SS.get_library_spell(id))
			var o1: Array = DS.make_offers()
			P("spells full (%d/%d), passives empty: offers=%s (no new cast spells=%s)" % [SS.spells.size(), DS.spellbook_cap, ids(o1), o1.all(func(s): return s.is_passive() or SS.owned_rank(s.family()) > 0)])
			for id in ["mana_conduit", "aura_of_mending", "vital_bond"]:
				SS.add_spell(SS.get_library_spell(id))
			P("passives go to the tray: spells=%s passives=%s" % [ids(SS.spells), ids(SS.passives)])
			var o2: Array = DS.make_offers()
			P("full (%d/%d spells, %d/%d passives): offers=%s (all rank-ups=%s)" % [SS.spells.size(), DS.spellbook_cap, SS.passives.size(), DS.passive_cap, ids(o2), o2.all(func(s): return SS.owned_rank(s.family()) > 0)])
			for id in ["shield_2", "heal_2", "heal_3"]:
				SS.add_spell(SS.get_library_spell(id))
			P("everything ranked up: spellbook=%s offers=%s" % [ids(SS.spells), ids(DS.make_offers())])
			var a = DS.offers_after_round(5); var b = DS.offers_after_round(10)
			P("RESULT build complete fires once: offers=%s/%s signal count=%d" % [ids(a), ids(b), complete])
			DS.swap_when_full = true
			# Real flow from a fresh run: school → round 1 → spell pick → contracts
			GM.new_game(); wait = 0.2
		3:
			game.card_panel._choose(0); wait = 0.6   # Mending
		4:
			game.party_choice_panel._on_left_chosen(); wait = 0.2
		5:
			GM.round_time = 0.01; wait = 0.3
		6:
			P("after round 1: pick screen=%s mode=%s offers=%s" % [game.card_panel.visible, game._card_mode, ids(game._card_options)])
			game.card_panel._choose(0); wait = 0.6
		7:
			P("after picking: spellbook=%s contract screen=%s round=%d" % [ids(SS.spells), game.party_choice_panel.visible, GM.current_round])
			game.party_choice_panel._on_left_chosen(); wait = 0.2
		8:
			GM.round_time = 0.01; wait = 0.3
		9:
			P("after round 2 (not a pick round): pick screen=%s contract screen=%s" % [game.card_panel.visible, game.party_choice_panel.visible])
			quit()
	step += 1
	return false
