extends SceneTree
# Spell batch 2 (#70): new spells and passives with real casts, the Mitigation tag (key PROTECT), offer
# gating, and the tag census (every tag: at least 2 spells have it and 2 react to it).
var game; var f := 0; var GM; var SS; var DS; var TS; var ES; var step := 0; var wait := 0.0
var combos := []; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func lib(id): return SS.get_library_spell(id)
func use(ids: Array): SS.set_spellbook_ids(PackedStringArray(ids))
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.current_health = v
	combos.clear(); GM.mana = 500.0; GM.max_mana = 999.0; SS.cooldowns.clear()
func hps(): return T.map(func(t): return roundi(hp(t)))

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); DS = root.get_node("DraftSystem")
			TS = root.get_node("TargetSystem"); ES = root.get_node("EffectSystem")
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			# Tag census
			var have := {}; var react := {}
			for s in SS.library:
				if s.rank != 1: continue
				for t in s.tags: have[t] = have.get(t, 0) + 1
				for t in s.reacts_to_tags: react[t] = react.get(t, 0) + 1
			P("tag census (spells that have it / react to it): %s" % [SpellTags.ALL.map(func(t): return "%s %d/%d" % [SpellTags.label(t), have.get(t, 0), react.get(t, 0)])])
			P("RESULT every tag has 2+ spells and 2+ reactors: %s" % SpellTags.ALL.all(func(t): return have.get(t, 0) >= 2 and react.get(t, 0) >= 2))
			P("library: %d entries" % SS.library.size())
			# Promise of Light: 40 after 3s
			use(["promise_of_light", "hasten"]); reset(10.0)
			ES.cast(lib("promise_of_light"), T[0]); wait = 3.1
		3:
			P("Promise of Light after 3s: #0=%d (50)" % roundi(hp(T[0])))
			# Hasten: Lifebloom lands now, 25% bigger
			use(["lifebloom", "hasten"]); reset(10.0)
			ES.cast(lib("lifebloom"), T[1])
			P("glow: Hasten on a fighter with Lifebloom=%s, without=%s" % [ES.would_combo(lib("hasten"), T[1]), ES.would_combo(lib("hasten"), T[2])])
			ES.cast(lib("hasten"), T[1])
			P("RESULT Hasten: #1=%d (10 + 45×1.25 = 66) delayed left=%d combos=%s" % [roundi(hp(T[1])), T[1].health_comp.get_statuses("DELAYED").size(), combos])
			# Ripening: Delayed heals on a fighter below 50% heal 50% more
			use(["lifebloom", "ripening"]); reset(10.0)
			var dh = load("res://components/statuses/DelayedHealStatus.gd").new(20.0, 0.1)
			ES.add_status(T[2], dh, lib("lifebloom"))
			P("glow: Lifebloom doesn't glow for Ripening (lands later)=%s" % (not ES.would_combo(lib("lifebloom"), T[2])))
			wait = 0.25
		4:
			P("RESULT Ripening: a 20 Delayed heal on a fighter at 10 → %d (40) combos=%s" % [roundi(hp(T[2])), combos])
			# Tranquility: every fighter 2/s for 6s
			use(["tranquility", "aura_of_mending"]); reset(10.0)
			ES.cast(lib("tranquility"), T[0]); wait = 2.05
		5:
			P("Tranquility + Aura of Mending after 2 ticks: %s (each 10 + 4 own + Aura splash from neighbours)" % [hps()])
			use(["tranquility"]); reset(10.0)
			ES.cast(lib("tranquility"), T[0]); wait = 2.05
		6:
			P("RESULT Tranquility alone after 2 ticks: %s (14 each)" % [hps()])
			# Aegis of Light: 12 shield on everyone; a fighter already shielded gets half (Diminishing)
			use(["aegis_of_light", "shield"]); reset(40.0)
			ES.cast(lib("shield"), T[3]); ES.cast(lib("aegis_of_light"), T[0])
			P("RESULT Aegis of Light: shields=%s (12, 12, 12, 30+6 diminished)" % [T.map(func(t): return roundi(t.health_comp.shield_amount))])
			# Lingering Light: Multi-target casts leave a 3/s heal-over-time on the target
			use(["chain_heal", "lingering_light"]); reset(10.0)
			ES.cast(lib("chain_heal"), T[1])
			var hot: Array = T[1].health_comp.get_statuses("HOT")
			P("RESULT Lingering Light: HoT on #1 after Chain Heal: %s" % [hot.map(func(h): return "%s %s/s %ss" % [h.label, h.per_second, h.duration])])
			# Rising Tide: every 3rd Multi-target cast gives 20 mana; the 3rd glows
			use(["chain_heal", "rising_tide"]); reset(10.0)
			var gains := []; var glows := []
			for i in 3:
				glows.append(ES.would_combo(lib("chain_heal"), T[0]))
				var m: float = GM.mana; ES.cast(lib("chain_heal"), T[0]); gains.append(roundi(GM.mana - m))
			P("RESULT Rising Tide: 3 Chain Heals → mana gains %s (0, 0, 20), glow before each %s (only the 3rd)" % [gains, glows])
			# Sanctuary: Mitigation spells add a 15 shield
			use(["divine_protection", "sanctuary"]); reset(40.0)
			ES.cast(lib("divine_protection"), T[2])
			P("RESULT Sanctuary: Divine Protection on #2 → shield %d (15) combos=%s" % [roundi(T[2].health_comp.shield_amount), combos])
			# Watchful Eye: Mitigation on a fighter below 40% heals 25; it glows there
			use(["time_stop", "watchful_eye"]); reset(10.0)
			P("glow: Time Stop on a fighter at 10 hp=%s; at full=%s" % [ES.would_combo(lib("time_stop"), T[0]), false])
			ES.cast(lib("time_stop"), T[0])
			T[1].health_comp.current_health = T[1].health_comp.max_health
			P("RESULT Watchful Eye: Time Stop on #0 at 10 hp → %d (35) combos=%s; on a full fighter glow=%s" % [roundi(hp(T[0])), combos, ES.would_combo(lib("time_stop"), T[1])])
			# Offer gating: Mitigation reactors only once you own a Mitigation spell
			use(["heal"])
			P("Sanctuary offered with only Heal=%s · after Divine Protection=%s" % [DS.requirements_met(lib("sanctuary")), (func(): use(["heal", "divine_protection"]); return DS.requirements_met(lib("sanctuary"))).call()])
			P("Hasten / Ripening need Delayed: with Lifebloom=%s" % [(func(): use(["lifebloom"]); return DS.requirements_met(lib("hasten")) and DS.requirements_met(lib("ripening"))).call()])
			quit()
	step += 1
	return false
