extends SceneTree
const C = preload("res://tools/tests/check.gd")
# Phase F (owner, 2026-10-25): debuffs and Cleanse.
# - schedule: none before round 6; from round 6 a debuff every few seconds, never on the Baron
# - Poison stacks (up to 3) and hurts; Bleed hurts until healed above 80% or bandaged, and
#   can't be cleansed; Hex halves heals (shields untouched); Dread kills at its line, a
#   death save (Guardian Angel) still works, and it's never put on a fighter near the line
# - Cleanse on F: removes Poison, Hex and Dread, uses a charge, charges refill in the round
# - Mend Wounds removes Poison; Purify (rank-up) has 3 charges and blocks new debuffs for 3s
# - Purging Light and Clean Slate react to a cleanse; the warning text above the fighter
# Pass a path to also save a screenshot.
var game; var f := 0; var GM; var SS; var TS; var ES; var CS; var DB; var D; var step := 0; var wait := 0.0; var shot := ""
var T := []; var combos := []; var died := []
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: shot = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func lib(id): return SS.get_library_spell(id)
func dnames(t): return t.health_comp.debuffs().map(func(d): return "%s%s" % [d.debuff, ("×%d" % d.stacks) if d.stacks > 1 else ""])
func reset(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.max_health = 100.0; t.health_comp.current_health = v
	combos.clear(); GM.mana = 500.0; SS.cooldowns.clear()

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem")
			ES = root.get_node("EffectSystem"); CS = root.get_node("CleanseSystem"); DB = root.get_node("DebuffSystem")
			D = root.get_node("DifficultySystem"); D.base_dps = 0.0; D.dps_growth = 0.0; D.burst_interval = 999.0
			root.get_node("EventBus").combo_fired.connect(func(_t, l): combos.append(l))
			root.get_node("EventBus").target_died.connect(func(t): died.append(t))
			P("debuff gaps by round: %s" % [[1, 5, 6, 7, 10, 20].map(func(r): return "%d:%.1fs" % [r, D.get_debuff_interval(r)])])
			game._on_start_pressed(); wait = 0.3
		1:
			game.card_panel._choose(0); wait = 0.5
		2:
			game.party_choice_panel._on_left_chosen(); wait = 0.4
		3:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("round %d: Cleanse on F = %s, charges %d/%d · counter: '%s'" % [GM.current_round, SS.utility.id, CS.charges, CS.max_charges(), game.hud.cleanse_label.get_parsed_text()])
			C.ok(game.hud.cleanse_label.get_parsed_text().to_upper().contains(SS.utility.display_name.to_upper()), "the F counter names the Cleanse spell")
			GM.round_time = 30.0
			wait = 3.0
		4:
			P("round 1 after 3s: debuffs on anyone = %s (none expected)" % [T.any(func(t): return not t.health_comp.debuffs().is_empty())])
			GM.current_round = 6; DB._on_round_started(6)
			reset(100.0)
			wait = DB._interval * 0.5 + 0.3
		5:
			P("round 6: first debuff after %.1fs → %s (timer now %.1f, in_round=%s)" % [DB._interval * 0.5, T.map(func(t): return dnames(t)), DB._timer, GM.in_round])
			# Poison stacks and hurts
			reset(100.0)
			for i in 4: DB.apply(T[0], "POISON")
			P("Poison ×4 doses → %s (max 3 stacks)" % [dnames(T[0])])
			# Hex halves heals; shields untouched
			DB.apply(T[1], "HEX")
			reset_hp(T[1], 20.0)
			ES.heal(T[1], 40.0, lib("heal"), ["DIRECT"])
			P("RESULT Hex: heal 40 on a hexed fighter → %d (20 + 20)" % roundi(hp(T[1])))
			ES.cast(lib("shield"), T[1])
			P("Hex and a 30 shield → shield %d (not weakened)" % roundi(T[1].health_comp.shield_amount))
			# Bleed
			DB.apply(T[2], "BLEED"); reset_hp(T[2], 60.0)
			# Dread
			DB.apply(T[3], "DREAD")
			wait = 2.0
		6:
			P("warnings above the fighters: %s" % [T.map(func(t): return t._debuff_label.get_parsed_text())])
			T[0].pending_burst_time = 3.0   # an INCOMING warning too, to see both
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot + "_debuffs.png"); print("saved debuffs")
			P("RESULT Poison ×3 over 2s: #0 = %d (100 − 3 × 1.2 × armour × 2s)" % roundi(hp(T[0])))
			P("Bleed over 2s: #2 = %d (fell from 60) · still bleeding=%s" % [roundi(hp(T[2])), T[2].health_comp.get_debuff("BLEED") != null])
			ES.heal(T[2], 40.0, lib("heal"), ["DIRECT"])
			wait = 0.2
		7:
			P("RESULT Bleed after a heal above 80%%: still bleeding=%s (false)" % (T[2].health_comp.get_debuff("BLEED") != null))
			DB.apply(T[2], "BLEED")
			CS.try_cleanse(T[2])
			P("Cleanse on a bleeder: removed=%s (Bleed can't be cleansed)" % (T[2].health_comp.get_debuff("BLEED") == null))
			CS.charges = CS.max_charges()
			CS.try_cleanse(T[0])
			P("RESULT Cleanse on Poison ×3: debuffs left=%s charges %d/%d" % [dnames(T[0]), CS.charges, CS.max_charges()])
			P("warning above #3 (Dread): '%s' · Dread line shown=%s" % [T[3]._debuff_label.get_parsed_text(), T[3]._dread_line.visible])
			wait = 0.2
		8:
			# Dread and Guardian Angel; Dread never on a fighter near the line
			reset(100.0); died.clear()
			DB.apply(T[1], "DREAD")
			ES.cast(lib("guardian_angel"), T[1])
			T[1].health_comp.take_damage(75.0)
			P("RESULT Dread + Guardian Angel: dead=%s hp=%d dread gone=%s" % [T[1].health_comp.is_dead, roundi(hp(T[1])), T[1].health_comp.get_debuff("DREAD") == null])
			reset_hp(T[2], 40.0)
			P("Dread on a fighter at 40%%: allowed=%s (false)" % DB.can_take(T[2], "DREAD"))
			# Charges refill during the round
			CS.charges = 0; CS._refill = 0.0
			wait = CS.charge_time() + 0.3
		9:
			P("charges after %.0fs: %d (1 back)" % [CS.charge_time(), CS.charges])
			# Mend Wounds removes Poison only
			reset(50.0)
			DB.apply(T[0], "POISON"); DB.apply(T[0], "HEX")
			ES.cast(lib("mend_wounds"), T[0])
			P("RESULT Mend Wounds on Poison + Hex → left %s (HEX)" % [dnames(T[0])])
			# Purify: 3 charges, no new debuffs for 3s
			SS.add_spell(lib("purify"))
			P("Purify on F: %s charges %d · card: '%s' · %s" % [SS.utility.id, CS.max_charges(), lib("purify").description_plain(), lib("purify").cost_line()])
			CS.charges = 3
			CS.try_cleanse(T[0])
			DB.apply(T[0], "POISON")
			P("RESULT Purify: Hex gone=%s, new Poison right after blocked=%s" % [T[0].health_comp.get_debuff("HEX") == null, T[0].health_comp.get_debuff("POISON") == null])
			# Passives that react to a cleanse
			SS.add_spell(lib("cleanse")); reset(50.0)
			SS.set_spellbook_ids(PackedStringArray(["heal", "purging_light", "clean_slate"]))
			SS.utility = lib("cleanse"); CS.charges = 2
			CS.try_cleanse(T[1])
			P("cleanse with nothing on: hp=%d shield=%d (no passive fires)" % [roundi(hp(T[1])), roundi(T[1].health_comp.shield_amount)])
			DB.apply(T[1], "POISON"); CS.try_cleanse(T[1])
			P("RESULT Purging Light + Clean Slate on a real cleanse: hp=%d (50 + 20) shield=%d (15) combos=%s" % [roundi(hp(T[1])), roundi(T[1].health_comp.shield_amount), combos])
			# Last: Dread kills at its line (this ends the run)
			reset(100.0)
			DB.apply(T[3], "DREAD")
			var line: float = T[3].health_comp.get_debuff("DREAD").threshold
			T[3].health_comp.take_damage(hp(T[3]) - line + 1.0)
			P("RESULT Dread: line at %d, fighter dropped to it → dead=%s" % [roundi(line), T[3].health_comp.is_dead])
			C.done(self)
	step += 1
	return false

func reset_hp(t, v): t.health_comp.current_health = v
