extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Passives as data (#65): the generic tag trigger (TagTriggerRule). Builds triggers in code
# and checks each kind of event and action, the conditions, and the card text.
var game; var f := 0; var GM; var SS; var TS; var ES; var step := 0; var wait := 0.0
var combos := []; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.current_health = v
	combos.clear(); GM.mana = 500.0; GM.max_mana = 999.0; SS.cooldowns.clear()

## A passive spell wrapping a trigger built from `fields`.
func passive(fields: Dictionary) -> SpellData:
	var r = load("res://resources/spells/passives/TagTriggerRule.gd").new()   # loaded late: it uses autoloads
	for k in fields:
		r.set(k, fields[k])
	var s := SpellData.new()
	s.id = "test_%d" % randi(); s.display_name = "Test passive"; s.passive = r
	return s

func use(list: Array) -> void:
	var book: Array[SpellData] = []
	for s in list: book.append(s)
	SS.set_spellbook(book)

func lib(id): return SS.get_library_spell(id)

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem"); ES = root.get_node("EffectSystem")
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			# HEALED + tag: a Delayed heal landing heals the whole party
			var p1 := passive({"event": "HEALED", "tags": ["DELAYED"] as Array[String], "action": "HEAL", "who": "PARTY", "amount": 5.0, "combo_label": "Bloom burst"})
			use([lib("lifebloom"), p1])
			P("text HEALED/DELAYED/PARTY: '%s'" % p1.description_plain())
			reset(10.0)
			var dh = load("res://components/statuses/DelayedHealStatus.gd").new(20.0, 0.2)
			ES.add_status(T[0], dh, lib("lifebloom")); wait = 0.35
		3:
			P("Delayed heal of 20 on #0 → hp=%s (#0: 10+20+5=35, others 15) combos=%s" % [str(T.map(func(t): return roundi(hp(t)))), combos])
			C.near(hp(T[0]), 35.0, "Delayed heal lands, then the passive heals the target 5"); C.near(hp(T[1]), 15.0, "and the rest of the party 5"); C.ok(combos.size() > 0, "the passive fires its combo")
			# A Direct heal doesn't set it off
			reset(10.0); ES.cast(lib("flash_heal"), T[0])
			P("Flash Heal (Direct, not Delayed) → others stay 10: %s" % str(T.map(func(t): return roundi(hp(t)))))
			C.near(hp(T[1]), 10.0, "a Direct heal does not set off a Delayed passive")
			# CAST + tag: casting a Multi-target spell leaves a heal-over-time on the target
			var p2 := passive({"event": "CAST", "tags": ["MULTI"] as Array[String], "action": "HOT", "who": "TARGET", "amount": 3.0, "duration": 4.0})
			use([lib("chain_heal"), p2])
			P("text CAST/MULTI/HOT: '%s'" % p2.description_plain())
			reset(10.0); ES.cast(lib("chain_heal"), T[1])
			var hots: Array = T[1].health_comp.get_statuses("HOT")
			P("Chain Heal on #1 → HoT on #1: %s (3/s for 4s), its tags=%s (none: triggered HoTs don't feed HoT combos)" % [hots.map(func(h): return "%s/s %ss" % [h.per_second, h.duration]), hots.map(func(h): return h.tags)])
			C.eq(hots.size(), 1, "casting a Multi-target spell leaves one HoT"); if hots.size() == 1: C.near(hots[0].per_second, 3.0, "3/s"); C.near(hots[0].duration, 4.0, "for 4s")
			# every_nth: every 3rd Direct cast gives 10 mana
			var p3 := passive({"event": "CAST", "tags": ["DIRECT"] as Array[String], "action": "MANA", "amount": 10.0, "every_nth": 3})
			use([lib("flash_heal"), p3])
			P("text every 3rd: '%s'" % p3.description_plain())
			reset(10.0)
			var gains := []
			for i in 6:
				var m: float = GM.mana; ES.cast(lib("flash_heal"), T[0]); gains.append(roundi(GM.mana - m))
			P("6 Flash Heals (cast directly, no cost) → mana gains %s (0,0,10,0,0,10)" % [gains])
			C.eq(gains, [0, 0, 10, 0, 0, 10], "every 3rd Direct cast gives 10 mana")
			# SHIELD_BROKEN + share: the party heals for what the shield absorbed
			var p4 := passive({"event": "SHIELD_BROKEN", "action": "HEAL", "who": "PARTY", "share": 1.0, "combo_label": "Shatter"})
			use([lib("shield"), p4])
			P("text SHIELD_BROKEN/PARTY/share: '%s'" % p4.description_plain())
			reset(10.0); ES.cast(lib("shield"), T[2]); T[2].health_comp.take_damage(40.0)
			P("Shield 30 on #2 broken by 40 → hp=%s (#2: 10-10+30=30, others 40) combos=%s" % [str(T.map(func(t): return roundi(hp(t)))), combos])
			C.near(hp(T[2]), 30.0, "shielded fighter: 10 - 10 + 30 shared"); C.near(hp(T[0]), 40.0, "everyone else heals 30")
			# EXTEND_HOTS on CAST Direct, below 50% health
			var p5 := passive({"event": "CAST", "tags": ["DIRECT"] as Array[String], "below_health": 0.5, "action": "EXTEND_HOTS", "duration": 3.0})
			use([lib("renew"), lib("flash_heal"), p5])
			P("text EXTEND_HOTS: '%s'" % p5.description_plain())
			reset(10.0); ES.cast(lib("renew"), T[3])
			var before: float = T[3].health_comp.hot_time
			ES.cast(lib("flash_heal"), T[3])
			P("Renew then Flash Heal on a low fighter: HoT %.1fs → %.1fs (+3)" % [before, T[3].health_comp.hot_time])
			C.near(T[3].health_comp.hot_time - before, 3.0, "Direct heal on a low fighter extends HoTs by 3s", 0.1)
			P("glow: Flash Heal on a fighter at 10%% would fire=%s; at full health=%s" % [p5.passive.would_combo(lib("flash_heal"), T[0]), p5.passive.would_combo(lib("flash_heal"), T[3])])
			C.ok(p5.passive.would_combo(lib("flash_heal"), T[0]), "glow on a low fighter"); C.ok(not p5.passive.would_combo(lib("flash_heal"), T[3]), "no glow at full health")
			# HEAL_BOOST and cooldown
			var p6 := passive({"event": "HEAL_BOOST", "action": "BOOST", "share": 1.0, "cooldown": 5.0})
			use([lib("flash_heal"), p6])
			P("text HEAL_BOOST/cooldown: '%s'" % p6.description_plain())
			reset(1.0); ES.cast(lib("flash_heal"), T[0]); ES.cast(lib("flash_heal"), T[1])
			P("two Flash Heals → #0 +%d (64 boosted, capped by max HP) #1 +%d (32, on cooldown)" % [roundi(hp(T[0]) - 1), roundi(hp(T[1]) - 1)])
			C.ok(hp(T[0]) - 1 > 40.0, "first heal is boosted"); C.near(hp(T[1]) - 1, 32.0, "second heal is not (cooldown)")
			P("RESULT trigger checks done")
			C.done(self)
	step += 1
	return false
