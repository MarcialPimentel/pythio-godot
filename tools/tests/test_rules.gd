extends SceneTree
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
	return " | ".join(game._rules_box.get_children().slice(1).map(func(l): return r.sub(l.text, "", true)))

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
			P("rule text: %s" % str(ES.battlefield_rules.map(func(r): return SpellTags.fill_plain(r.describe()))))
			# Diminishing shields
			SS.set_spellbook_ids(PackedStringArray(["shield", "guardian_ward", "flash_heal"]))
			reset(40.0); cast("shield", T[0]); cast("guardian_ward", T[0])
			P("Diminishing: Shield 30 then Guardian Ward 25 → total shield %.1f (30 + 12.5 = 42.5)" % T[0].health_comp.shield_amount)
			SS.set_spellbook_ids(PackedStringArray(["shield", "guardian_ward", "flash_heal", "bulwark"]))
			reset(40.0); cast("shield", T[1]); cast("guardian_ward", T[1])
			P("Bulwark: same casts → %.1f (34.5 + 28.75 = 63.25) · rules: %s" % [T[1].health_comp.shield_amount, rules_text()])
			# Exhaustion
			SS.set_spellbook_ids(PackedStringArray(["shield"]))
			reset(40.0); GM.mana = 20.0; cast("shield", T[2]); wait = 0.05
		3:
			P("Exhaustion: Shield (14) from 20 mana leaves %.0f → exhausted for %.1fs, label '%s'" % [GM.mana, GM.exhausted_time, game.mana_label.text])
			GM.mana = 0.0; GM.regen_mana(1.0)
			P("  regen over 1s while exhausted: %.1f (4 × 50%% = 2)" % GM.mana)
			SS.set_spellbook_ids(PackedStringArray(["shield", "second_wind"]))
			reset(40.0); GM.mana = 20.0; cast("shield", T[2]); wait = 0.05
		4:
			var after: float = GM.mana
			P("Second Wind: Shield from 20 → %.0f (6 + 30 = 36), exhausted=%.1fs · rules: %s" % [after, GM.exhausted_time, rules_text()])
			GM.mana = 20.0; cast("shield", T[3]); wait = 0.05
		5:
			P("  again within 20s: mana %.0f (6, on cooldown)" % GM.mana)
			# Saturation
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "renew"]))
			reset(10.0); T[0].health_comp.current_health = T[0].health_comp.max_health - 5.0
			cast("flash_heal", T[0]); wait = 0.05
		6:
			P("Saturation: Flash Heal with 5 missing → saturated=%s" % T[0].health_comp.has_status("SATURATED"))
			T[0].health_comp.current_health = 10.0; var b: float = hp(T[0]); cast("flash_heal", T[0])
			P("  next Flash Heal heals %.1f (32 × 0.7 = 22.4); saturated now=%s" % [hp(T[0]) - b, T[0].health_comp.has_status("SATURATED")])
			reset(10.0); T[1].health_comp.current_health = T[1].health_comp.max_health - 1.0
			cast("renew", T[1]); wait = 2.1
		7:
			P("  Renew ticks overhealing never saturate: saturated=%s" % T[1].health_comp.has_status("SATURATED"))
			SS.set_spellbook_ids(PackedStringArray(["flash_heal", "overflow"]))
			reset(10.0); T[2].health_comp.current_health = T[2].health_comp.max_health - 5.0
			cast("flash_heal", T[2]); wait = 0.05
		8:
			P("Overflow: overheal 27 → shield %.1f (13.5), saturated=%s · rules: %s" % [T[2].health_comp.shield_amount, T[2].health_comp.has_status("SATURATED"), rules_text()])
			quit()
	step += 1
	return false
