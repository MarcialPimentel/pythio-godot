extends SceneTree
# A simple bot that plays real runs, for balance checks (not a pass/fail test).
# Usage: godot --headless --script tools/tests/sim_bot.gd -- <runs per school> [time scale]
# Each school is played <runs> times; prints the round reached and the spells picked.
# The bot: shields a fighter with an incoming burst if it can, otherwise heals whoever is
# lowest (below 85%) with the best spell it can afford, keeps HoTs up, and on picks takes
# the first card that combos with its spellbook (else the first card).
var game; var GM; var SS; var DS; var TS
var runs := 3; var scale := 4.0; var kit: PackedStringArray = []
var school_i := 0; var run_i := 0; var results := {}
var think := 0.0
## Per-round bookkeeping, printed when a round ends.
var stat := {"healed": 0.0, "overheal": 0.0, "burst": 0.0, "casts": 0, "idle_mana_low": 0}
const SCHOOLS := ["Mending", "Bloom", "Ward"]

func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: runs = int(a[0])
	if a.size() > 1: scale = float(a[1])
	if a.size() > 2: kit = a[2].split(",")   # optional fixed spellbook, e.g. flash_heal,renew,shield
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)

var started := false
func _process(d):
	if GM == null:
		GM = root.get_node_or_null("GameManager"); SS = root.get_node_or_null("SpellSystem")
		DS = root.get_node_or_null("DraftSystem"); TS = root.get_node_or_null("TargetSystem")
		if GM == null: return false
		GM.game_over.connect(_on_over)
		var EB = root.get_node("EventBus")
		EB.healed.connect(func(_t, a, o, _s, _g): stat.healed += a; stat.overheal += o)
		EB.burst_landed.connect(func(_t, _a, dealt): stat.burst += dealt)
		EB.spell_cast.connect(func(_s, _t): stat.casts += 1)
		EB.round_ended.connect(_on_round_end)
		EB.target_died.connect(func(t): print("SIM     death: %s (%s, max %.0f) at %.1fs left · statuses %s · recent bursts on them: %s" % [t.display_name, t.armor_type, t.health_comp.max_health, GM.round_time, t.health_comp.statuses.map(func(s): return s.kind), t.get_meta("bursts", 0)]))
		EB.burst_landed.connect(func(t, _a, dealt): t.set_meta("bursts", t.get_meta("bursts", 0) + 1))
		Engine.time_scale = scale
		return false
	if not started:
		started = true
		game._on_start_pressed()
		return false
	if game.card_panel.visible and not game.card_panel._locked:
		_pick()
	elif game.party_choice_panel.visible and not GM.in_round and not game.game_over_panel.visible:
		game.party_choice_panel._on_left_chosen()
	elif GM.in_round:
		think -= d
		if think <= 0.0:
			think = 0.15
			_act()
	return false

func _pick():
	if game._card_mode == "spec":
		game.card_panel._choose(school_i)
		if not kit.is_empty():
			(func(): SS.set_spellbook_ids(kit)).call_deferred()
		return
	# Like a sensible player: rank-ups, then more healing, then combos, then anything.
	var opts: Array = game._card_options
	var score := func(s):
		if SS.owned_rank(s.family()) > 0: return 4
		if s.tags.has("DIRECT") or s.tags.has("HOT") or s.tags.has("MULTI"): return 3
		if DS.has_synergy(s) or s.tags.has("SHIELD"): return 2
		return 1
	var best := 0
	for i in opts.size():
		if score.call(opts[i]) > score.call(opts[best]): best = i
	game.card_panel._choose(best)

func _castable(pred: Callable) -> Array:
	return SS.spells.filter(func(s): return not s.is_passive() and SS.can_cast(s) and pred.call(s))

var why := {}
func _note(k): why[k] = why.get(k, 0) + 1
func _act():
	if SS.is_casting: _note("casting"); return
	var alive: Array = TS.targets.filter(func(t): return is_instance_valid(t) and not t.health_comp.is_dead)
	# 1) incoming burst → shield / protect it
	for t in alive:
		if t.pending_burst_time > 0.0 and t.health_comp.shield_amount <= 0.0:
			var def := _castable(func(s): return s.tags.has("SHIELD") or s.id in ["divine_protection", "time_stop"])
			if not def.is_empty():
				SS.request_cast(def[0], t); return
	# 2) lowest fighter below 85%
	alive.sort_custom(func(a, b): return a.health_comp.current_health / a.health_comp.max_health < b.health_comp.current_health / b.health_comp.max_health)
	if alive.is_empty(): return
	var heals := _castable(func(s): return s.tags.has("DIRECT") or s.tags.has("HOT") or s.tags.has("DELAYED") or s.tags.has("SHIELD"))
	for low in alive:
		var frac: float = low.health_comp.current_health / low.health_comp.max_health
		if frac >= 0.85: break
		var order := heals.duplicate()
		if frac < 0.35:
			order.sort_custom(func(a, b): return a.cast_time < b.cast_time)   # emergency: fastest first
		for s in order:
			if s.tags.has("HOT") and low.health_comp.hot_time > 1.0: continue
			if s.tags.has("DELAYED") and low.health_comp.has_status("DELAYED"): continue
			if s.tags.has("SHIELD") and not s.tags.has("DIRECT") and low.health_comp.shield_amount > 0.0: continue
			SS.request_cast(s, low); _note("heal " + s.id); return
	_note("nothing to do")
	# 3) keep a HoT or shield rolling on someone without one
	for t in alive:
		var keep := _castable(func(s): return (s.tags.has("HOT") and t.health_comp.hot_time <= 0.5) or (s.tags.has("SHIELD") and t.health_comp.shield_amount <= 0.0))
		if not keep.is_empty() and GM.mana > GM.max_mana * 0.5:
			SS.request_cast(keep[0], t); return

func _on_round_end(r):
	var party: Array = TS.targets.filter(func(t): return is_instance_valid(t))
	var hp := 0.0; var mx := 0.0
	for t in party: hp += t.health_comp.current_health; mx += t.health_comp.max_health
	print("SIM   round %d (%d fighters, %.0f HP max): healed %.0f (+%.0f overheal) · burst damage %.0f · casts %d · mana left %.0f/%.0f · party HP left %.0f%%" % [r, party.size(), mx, stat.healed, stat.overheal, stat.burst, stat.casts, GM.mana, GM.max_mana, hp / maxf(1.0, mx) * 100.0])
	print("SIM     decisions: %s" % why); why = {}
	stat = {"healed": 0.0, "overheal": 0.0, "burst": 0.0, "casts": 0, "idle_mana_low": 0}

func _on_over(round_reached: int, _score: int):
	var key: String = SCHOOLS[school_i]
	if not results.has(key): results[key] = []
	results[key].append("R%d %s" % [round_reached, SS.spells.map(func(s): return s.id)])
	print("SIM: %s run %d → fell in round %d · spellbook %s" % [key, run_i + 1, round_reached, SS.spells.map(func(s): return s.id)])
	run_i += 1
	if run_i >= runs:
		run_i = 0; school_i += 1
	if school_i >= SCHOOLS.size():
		for k in results: print("SIM SUMMARY %s: %s" % [k, results[k].map(func(r): return r.split(" ")[0])])
		quit(); return
	game.play_again_button.emit_signal.call_deferred("pressed")
