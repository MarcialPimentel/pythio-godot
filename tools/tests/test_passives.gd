extends SceneTree
const C = preload("res://tools/tests/check.gd")
# The four passives and the remaining spells, with real casts.
var game; var f := 0; var GM; var SS; var TS; var step := 0; var wait := 0.0
var combos := []; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func cast(id: String, t): SS.request_cast(SS.get_library_spell(id), t)
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.current_health = v
	combos.clear(); GM.mana = 500.0; GM.max_mana = 999.0; SS.cooldowns.clear()

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("passive card text: %s" % str(["seraphic_blessing", "aura_of_mending", "vital_bond", "mana_conduit"].map(func(id): return SS.get_library_spell(id).description_plain())))
			# Seraphic Blessing: Direct heals on a fighter below 40% heal 30% more
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "seraphic_blessing"]))
			reset(10.0); cast("flash_heal", T[0]); wait = 0.1
		3:
			var low: float = hp(T[0]) - 10.0
			T[0].health_comp.current_health = T[0].health_comp.max_health * 0.6; combos.clear()
			var start: float = hp(T[0]); SS.cooldowns.clear(); cast("flash_heal", T[0])
			P("Seraphic: Flash Heal at low health healed %.1f (32×1.3=41.6, less if it hits max HP) · at %.0f%% health healed %.0f (32, capped by max HP) combos at 60%%=%s" % [low, start / T[0].health_comp.max_health * 100.0, hp(T[0]) - start, combos])
			# Aura of Mending: HoT ticks splash 30% onto neighbours
			SS.set_spellbook_ids(PackedStringArray(["renew", "aura_of_mending"]))
			reset(10.0); cast("renew", T[1]); wait = 2.05
		4:
			P("Aura: after 2 Renew ticks on #1: #0=%.1f #1=%.1f #2=%.1f #3=%.1f (expect 13, 20, 13, 10)" % [hp(T[0]), hp(T[1]), hp(T[2]), hp(T[3])])
			# Vital Bond: a breaking shield gives neighbours a 10 shield; a fading one doesn't
			SS.set_spellbook_ids(PackedStringArray(["shield", "vital_bond"]))
			reset(40.0); cast("shield", T[1]); wait = 0.1
		5:
			T[1].health_comp.take_damage(35.0)
			P("Vital Bond: shield broke → neighbour shields #0=%.0f #2=%.0f (10 each) #3=%.0f · combos=%s" % [T[0].health_comp.shield_amount, T[2].health_comp.shield_amount, T[3].health_comp.shield_amount, combos])
			T[0].health_comp.take_damage(15.0)
			P("Vital Bond shields don't chain: #0 bond shield broke → #1 shield=%.0f (0)" % T[1].health_comp.shield_amount)
			# Mana Conduit: 20% of overheal comes back as mana
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "mana_conduit"]))
			reset(0.0); T[2].health_comp.current_health = T[2].health_comp.max_health - 12.0
			var m: float = GM.mana; cast("flash_heal", T[2])
			P("Mana Conduit: Flash Heal (32) with 12 missing → overheal 20 → mana %+.1f (−20 cost +4 refund = −16)" % (GM.mana - m))
			# Remaining spells
			SS.set_spellbook_ids(PackedStringArray(["binding_heal", "guardian_angel", "healing_plague", "time_stop", "divine_channel"]))
			reset(20.0); T[3].health_comp.current_health = 5.0
			cast("binding_heal", T[0]); wait = 1.6
		6:
			P("Binding Heal on #0: #0=%.0f (50) most injured #3=%.0f (25)" % [hp(T[0]), hp(T[3])])
			reset(20.0); cast("healing_plague", T[1]); wait = 1.5 + 2.05
		7:
			P("Healing Plague on #1 after 2 ticks: %s (28, 28, 28, 20)" % str(T.map(func(t): return hp(t))))
			reset(20.0); cast("guardian_angel", T[2]); wait = 0.1
		8:
			T[2].health_comp.take_damage(999.0)
			P("Guardian Angel vs 999 damage: alive=%s hp=%.0f (31) combos=%s" % [not T[2].health_comp.is_dead, hp(T[2]), combos])
			cast("time_stop", T[3]); wait = 0.1
		9:
			T[3].health_comp.take_damage(999.0)
			P("Time Stop vs 999 damage: hp=%.0f (20)" % hp(T[3]))
			GM.mana = 10.0; cast("divine_channel", T[0]); wait = 3.2
		10:
			P("Divine Channel (3s cast): mana=%.0f (10 + 50 + ~13 regen during the cast)" % GM.mana)
			C.done(self)
	step += 1
	return false
