extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Phase E (owner, 2026-10-25): spells from ordinary picks, passives from the Baron.
# - the schedule: spell picks after 1, 3, 7, 9 …; a passive pick after 5, 10, 15 …
# - spell picks offer only spells; Baron picks offer only passives, leaning toward your tags
# - the "Baron's bounty" screen: no Skip; with full passive slots, a "spell instead" card
# - the six new passives with real casts: Double Down, Wildgrowth, Shatterpoint, Harvest,
#   Chain Reaction, Bastion
# Pass a path to also save a screenshot of the Baron's bounty screen.
var game; var f := 0; var GM; var SS; var DS; var TS; var ES; var step := 0; var wait := 0.0; var shot := ""
var combos := []; var T := []
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: shot = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func lib(id): return SS.get_library_spell(id)
func use(ids: Array): SS.set_spellbook_ids(PackedStringArray(ids))
func ids(a): return a.map(func(s): return s.id if s is Resource else str(s))
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.max_health = 500.0; t.health_comp.current_health = v
	combos.clear(); GM.mana = 500.0; GM.max_mana = 999.0; SS.cooldowns.clear()

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); DS = root.get_node("DraftSystem")
			TS = root.get_node("TargetSystem"); ES = root.get_node("EffectSystem")
			var Diff = root.get_node("DifficultySystem"); Diff.base_dps = 0.0; Diff.burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(_t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.3
		1:
			game.card_panel._choose(1); wait = 0.5   # Renew
		2:
			game.party_choice_panel._on_left_chosen(); wait = 0.4
		3:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("schedule 1–20: %s" % [range(1, 21).filter(func(r): return DS.pick_kind(r) != "").map(func(r): return "%d %s" % [r, DS.pick_kind(r)])])
			# Offer kinds and tag lean (owning Renew = Heal-over-Time)
			var spell_passives := 0; var bounty_spells := 0; var bounty_hot := 0; var bounty_total := 0
			for i in 200:
				spell_passives += DS.make_offers("spell").filter(func(s): return s.is_passive()).size()
				var b = DS.make_offers("passive")
				bounty_spells += b.filter(func(s): return not s.is_passive()).size()
				bounty_total += b.size()
				bounty_hot += b.filter(func(s): return s.reacts_to_tags.has("HOT") or s.tags.has("HOT")).size()
			P("200 rolls: passives on spell picks=%d (0) · spells on Baron picks=%d (0) · Baron offers about Heal-over-Time: %d of %d" % [spell_passives, bounty_spells, bounty_hot, bounty_total])
			C.eq(spell_passives, 0, "spell picks never offer passives"); C.eq(bounty_spells, 0, "the Baron never offers spells")
			P("Baron passives offered with only Renew: %s" % [ids(DS.make_offers("passive"))])
			# The bounty screen after round 5
			GM.in_round = false   # as after a real Baron round
			game._show_spell_pick(DS.offers_after_round(5), 5)
			wait = 0.4
		4:
			P("bounty screen: title='%s' header='%s' options=%s (no Skip)" % [game.card_panel._title.text, game.timer_label.text, ids(game._card_options)])
			C.ok(not ids(game._card_options).has(game.SKIP), "the bounty has no Skip")
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot + "_bounty.png"); print("saved bounty")
			game.card_panel.close()
			# Full passives: swaps plus "a spell instead"
			use(["renew", "aura_of_mending", "second_wind", "mana_conduit"])
			game._show_spell_pick(DS.offers_after_round(10), 10)
			wait = 0.6
		5:
			var opts: Array = ids(game._card_options)
			P("full passives (3/3): options=%s has 'spell instead'=%s" % [opts, opts.has(game.BONUS_SPELL)])
			C.ok(opts.has(game.BONUS_SPELL), "full passives offer a spell instead")
			game.card_panel._choose(opts.find(game.BONUS_SPELL))
			wait = 0.4
		6:
			P("chose a spell instead: mode=%s offers=%s all spells=%s skip there=%s passives kept=%s" % [game._card_mode, ids(game._last_offers),
				game._last_offers.all(func(s): return not s.is_passive()), ids(game._card_options).has(game.SKIP), ids(SS.passives)])
			C.ok(game._last_offers.all(func(s): return not s.is_passive()), "a spell instead offers spells")
			C.ok(not ids(game._card_options).has(game.SKIP), "the spell pick from the bounty has no Skip")
			C.eq(SS.passives.size(), 3, "your passives are kept")
			game.card_panel.close(); game._card_mode = ""
			# Double Down: every 4th Direct heal lands twice
			use(["heal", "double_down"]); reset(10.0)
			for i in 4: ES.cast(lib("heal"), T[0])
			P("RESULT Double Down: 4 Heals on #0 → %d (10 + 4×30 + 30 = 160) combos=%s" % [roundi(hp(T[0])), combos])
			C.near(hp(T[0]), 160.0, "Double Down: the 4th Direct heal lands twice")
			# Wildgrowth: casting a HoT extends every HoT on the party by 2s
			use(["renew", "wildgrowth"]); reset(10.0)
			ES.cast(lib("renew"), T[0])
			ES.cast(lib("renew"), T[1])
			var t0 = T[0].health_comp.get_statuses("HOT")[0].time_left
			P("RESULT Wildgrowth: Renew on #0 then #1 → #0 Renew has %.1fs (8 + 2 = 10: a new HoT extends the ones already out) combos=%s" % [t0, combos])
			C.near(t0, 10.0, "Wildgrowth: a new HoT extends the others by 2s", 0.2)
			# Shatterpoint: a breaking shield heals every fighter 40% of what it held (up to 12)
			use(["shield", "shatterpoint"]); reset(10.0)
			ES.cast(lib("shield"), T[0])
			T[0].health_comp.take_damage(40.0)
			P("RESULT Shatterpoint: 30 shield broken on #0 → others %s (10 + 12 = 22) combos=%s" % [T.slice(1).map(func(t): return roundi(hp(t))), combos])
			C.ok(T.slice(1).all(func(t): return absf(hp(t) - 22.0) < 0.6), "Shatterpoint heals everyone 12")
			# Harvest: a Delayed heal also heals your most injured for 50%
			use(["lifebloom", "harvest"]); reset(100.0); T[3].health_comp.current_health = 5.0
			var dh = load("res://components/statuses/DelayedHealStatus.gd").new(40.0, 0.1)
			GM.in_round = true   # statuses only tick during a round
			ES.add_status(T[0], dh, lib("lifebloom"))
			wait = 0.3
		7:
			P("RESULT Harvest: Delayed 40 lands on #0 → most injured #3 %d (5 + 20 = 25) combos=%s" % [roundi(hp(T[3])), combos])
			C.near(hp(T[3]), 25.0, "Harvest heals the most injured 50%")
			# Chain Reaction: a Multi-target cast also heals your most injured for 15
			use(["chain_heal", "chain_reaction"]); reset(100.0); T[3].health_comp.current_health = 5.0
			ES.cast(lib("chain_heal"), T[0])
			P("RESULT Chain Reaction: Chain Heal on #0 → most injured #3 %d (5 + 15 = 20) combos=%s" % [roundi(hp(T[3])), combos])
			C.near(hp(T[3]), 20.0, "Chain Reaction heals the most injured 15")
			# Bastion: a Mitigation cast shields every fighter for 8
			use(["divine_protection", "bastion"]); reset(100.0)
			ES.cast(lib("divine_protection"), T[0])
			P("RESULT Bastion: Divine Protection on #0 → shields %s (8 each) combos=%s" % [T.map(func(t): return roundi(t.health_comp.shield_amount)), combos])
			C.ok(T.all(func(t): return absf(t.health_comp.shield_amount - 8.0) < 0.6), "Bastion shields everyone for 8")
			C.done(self)
	step += 1
	return false
