extends SceneTree
# Bursts: a warning, then the hit lands after burst_telegraph_time.
# Checks: damage matches the formula, a shield absorbs it, the warning label shows the
# number, and bursts stop when the round ends.
var game; var f := 0; var GM; var DS; var TS; var EB
var warned := []; var landed := []; var phase := 0; var t0 := 0.0; var shielded = null
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func now() -> float: return Time.get_ticks_msec() / 1000.0
func _process(_d):
	f += 1
	if f == 3:
		GM = root.get_node("GameManager"); DS = root.get_node("DifficultySystem"); TS = root.get_node("TargetSystem"); EB = root.get_node("EventBus")
		DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 1.0
		EB.burst_warned.connect(func(t, dmg, delay): warned.append([t, dmg, delay, now(), t.incoming_label.text]))
		EB.burst_landed.connect(func(t, a, d): landed.append([t, a, d, now(), t.health_comp.current_health]))
		game._on_start_pressed()
	if f > 3 and phase == 0 and game.party_choice_panel.visible and not GM.in_round:
		game.party_choice_panel._on_left_chosen(); phase = 1; t0 = now()
	if phase == 1 and warned.size() == 1 and landed.size() == 0 and not has_meta("lbl"):
		set_meta("lbl", true); P("warning label reads '%s'" % warned[0][0].incoming_label.text)
	if phase == 1 and landed.size() >= 1:
		var w = warned[0]; var l = landed[0]; var t = l[0]
		var expect: float = DS.get_burst_damage(1, t.armor_type, false)
		P("warned %s (%s armor) for %.1f" % [t.display_name, t.armor_type, w[1]])
		P("landed after %.2fs (telegraph %.1fs): absorbed=%.1f dealt=%.1f expected=%.1f hp now %.1f/%.0f" % [l[3] - w[3], DS.burst_telegraph_time, l[1], l[2], expect, l[4], t.health_comp.max_health])
		P("RESULT damage-correct=%s" % (absf(l[2] - expect) < 0.01 and l[1] == 0.0))
		phase = 2
	if phase == 2:
		# Shield every fighter, then wait for the next burst to land
		for t in TS.targets: t.health_comp.apply_shield(500.0, 30.0)
		landed.clear(); phase = 3
	if phase == 3 and landed.size() >= 1:
		var l = landed[0]
		P("shielded burst: absorbed=%.1f dealt=%.1f  RESULT shield-absorbs=%s" % [l[1], l[2], l[2] == 0.0 and l[1] > 0.0])
		phase = 4
	if phase == 4:
		GM.end_round(true); phase = 5; t0 = now(); landed.clear()
		P("RESULT round-end-clears-pending=%s" % (TS.pending_bursts.size() == 0))
	if phase == 5 and now() - t0 > 0.5:
		P("RESULT no-burst-between-rounds=%s" % (landed.size() == 0))
		quit()
	if f > 20000: P("TIMEOUT"); quit()
	return false
