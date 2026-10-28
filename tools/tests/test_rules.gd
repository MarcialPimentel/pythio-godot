extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Battlefield rules and their mirrored passives:
# Diminishing shields ↔ Bulwark, Exhaustion ↔ Second Wind, Saturation (soft) ↔ Overflow.
var game; var f := 0; var GM; var SS; var TS; var ES; var step := 0; var wait := 0.0; var T := []
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func cast(id: String, t): SS.cooldowns.clear(); return SS.request_cast(SS.get_library_spell(id), t)
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.current_health = v
	GM.mana = 500.0; GM.max_mana = 999.0; GM.exhausted_time = 0.0
func rules_text() -> String:
	var r := RegEx.new(); r.compile("\\[[^\\]]*\\]")
	return " | ".join(game.hud.rules_box.get_children().slice(1).map(func(l): return r.sub(l.text, "", true)))

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(2)   # Ward
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem"); ES = root.get_node("EffectSystem")
			var DS = root.get_node("DifficultySystem"); DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			game._on_start_pressed(); wait = 0.8
		1:
			game.party_choice_panel._on_left_chosen(); wait = 0.3
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("rules on screen: %s" % rules_text())
			C.ok(rules_text().contains("Diminishing") and rules_text().contains("Exhaustion") and rules_text().contains("Saturation"), "the rules panel lists all three rules")
			P("rule text: %s" % str(ES.battlefield_rules.map(func(r): return SpellTags.fill_plain(r.describe()))))
			# Diminishing shields
			SS.set_spellbook_ids(PackedStringArray(["shield", "guardian_ward", "flash_heal"]))
			reset(40.0); cast("shield", T[0]); cast("guardian_ward", T[0])
			P("Diminishing: Shield 30 then Guardian Ward 25 → total shield %.1f (30 + 12.5 = 42.5)" % T[0].health_comp.shield_amount)
			C.near(T[0].health_comp.shield_amount, 42.5, "a second, different shield absorbs 50% less")
			SS.set_spellbook_ids(PackedStringArray(["shield", "guardian_ward", "flash_heal", "bulwark"]))
			reset(40.0); cast("shield", T[1]); cast("guardian_ward", T[1])
			P("Bulwark: same casts → %.1f (34.5 + 28.75 = 63.25) · rules: %s" % [T[1].health_comp.shield_amount, rules_text()])
			C.near(T[1].health_comp.shield_amount, 63.25, "Bulwark: shields stack at full strength, +15%")
			# Owner, 2026-10-28: recasting the same shield refreshes it at full strength
			SS.set_spellbook_ids(PackedStringArray(["shield", "flash_heal"]))
			reset(40.0); cast("shield", T[2]); T[2].health_comp.take_damage(10.0); cast("shield", T[2])
			C.near(T[2].health_comp.shield_amount, 30.0, "recasting your Shield refreshes it to 30 (not halved)")
			# Shields from passives follow the shield rules too (review 2026-10-28)
			SS.set_spellbook_ids(PackedStringArray(["shield", "divine_protection", "sanctuary"]))
			reset(40.0); cast("shield", T[3]); cast("divine_protection", T[3])
			C.near(T[3].health_comp.shield_amount, 37.5, "Sanctuary's 15 shield on top of a Shield is halved (30 + 7.5)")
			SS.set_spellbook_ids(PackedStringArray(["divine_protection", "sanctuary", "bulwark"]))
			reset(40.0); cast("divine_protection", T[3])
			C.near(T[3].health_comp.shield_amount, 17.25, "Bulwark makes Sanctuary's shield 15% bigger")
			# Exhaustion
			SS.set_spellbook_ids(PackedStringArray(["shield"]))
			reset(40.0); GM.mana = 20.0; cast("shield", T[2]); wait = 0.05
		3:
			P("Exhaustion: Shield (14) from 20 mana leaves %.0f → exhausted for %.1fs, label '%s'" % [GM.mana, GM.exhausted_time, game.mana_label.text])
			C.near(GM.mana, 6.0, "Shield costs 14", 1.5); C.ok(GM.exhausted_time > 0.0, "running dry exhausts you")
			GM.mana = 0.0; GM.regen_mana(1.0)
			P("  regen over 1s while exhausted: %.1f (4 × 50%% = 2)" % GM.mana)
			C.near(GM.mana, 2.0, "exhausted regen is half speed")
			SS.set_spellbook_ids(PackedStringArray(["shield", "second_wind"]))
			reset(40.0); GM.mana = 20.0; cast("shield", T[2]); wait = 0.05
		4:
			var after: float = GM.mana
			P("Second Wind: Shield from 20 → %.0f (6 + 30 = 36), exhausted=%.1fs · rules: %s" % [after, GM.exhausted_time, rules_text()])
			C.near(after, 36.0, "Second Wind gives 30 mana", 1.5); C.near(GM.exhausted_time, 0.0, "and cancels exhaustion")
			GM.mana = 20.0; cast("shield", T[3]); wait = 0.05
		5:
			P("  again within 20s: mana %.0f (6, on cooldown)" % GM.mana)
			C.near(GM.mana, 6.0, "Second Wind is on cooldown", 1.5)
			# Saturation
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "renew"]))
			reset(10.0); T[0].health_comp.current_health = T[0].health_comp.max_health - 5.0
			cast("flash_heal", T[0]); wait = 0.05
		6:
			P("Saturation: Flash Heal with 5 missing → saturated=%s" % T[0].health_comp.has_status("SATURATED"))
			C.ok(T[0].health_comp.has_status("SATURATED"), "big overheal saturates")
			T[0].health_comp.current_health = 10.0; var b: float = hp(T[0]); cast("flash_heal", T[0])
			P("  next Flash Heal heals %.1f (32 × 0.7 = 22.4); saturated now=%s" % [hp(T[0]) - b, T[0].health_comp.has_status("SATURATED")])
			C.near(hp(T[0]) - b, 22.4, "saturated heal is 30% weaker")
			reset(10.0); T[1].health_comp.current_health = T[1].health_comp.max_health - 1.0
			cast("renew", T[1]); wait = 2.1
		7:
			P("  Renew ticks overhealing never saturate: saturated=%s" % T[1].health_comp.has_status("SATURATED"))
			C.ok(not T[1].health_comp.has_status("SATURATED"), "HoT ticks never saturate")
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "overflow"]))
			reset(10.0); T[2].health_comp.current_health = T[2].health_comp.max_health - 5.0
			cast("flash_heal", T[2]); wait = 0.05
		8:
			P("Overflow: overheal 27 → shield %.1f (13.5), saturated=%s · rules: %s" % [T[2].health_comp.shield_amount, T[2].health_comp.has_status("SATURATED"), rules_text()])
			C.near(T[2].health_comp.shield_amount, 13.5, "Overflow turns half the overheal into a shield"); C.ok(not T[2].health_comp.has_status("SATURATED"), "Overflow cancels Saturation")
			C.done(self)
	step += 1
	return false
