extends SceneTree
# Effect system: every effect type and status, tags in descriptions, passive hooks, combos.
# Builds throwaway spells in code, casts them on a real party with damage switched off.
var game; var f := 0; var GM; var TS; var SS; var EB; var DS
var combos := []; var step := 0; var wait := 0.0; var T := []; var direct: SpellData; var ES

class DoubleDirect extends PassiveRule:
	func modify_heal(amount: float, _t: Node, tags: Array, _o: Dictionary) -> float:
		return amount * 2.0 if tags.has("DIRECT") else amount

func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func hp(t): return t.health_comp.current_health
func setall(v):
	for t in T:
		t.health_comp.statuses.clear(); t.health_comp.current_health = v

func make(id: String, tags: Array, effects: Array, passive: PassiveRule = null) -> SpellData:
	var s := SpellData.new(); s.id = id; s.display_name = id.capitalize()
	var tg: Array[String] = []; tg.assign(tags); s.tags = tg
	var ef: Array[SpellEffect] = []; ef.assign(effects); s.effects = ef
	s.passive = passive
	return s
func eff(cls: String, props: Dictionary):
	var e = load("res://resources/spells/effects/%s.gd" % cls).new()
	for k in props: e.set(k, props[k])
	return e

func _process(d):
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked:
		game.card_panel._choose(0)
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); TS = root.get_node("TargetSystem"); SS = root.get_node("SpellSystem"); ES = root.get_node("EffectSystem"); EB = root.get_node("EventBus"); DS = root.get_node("DifficultySystem")
			DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			EB.combo_fired.connect(func(t, l): combos.append(l))
			game._on_start_pressed(); wait = 0.1
		1:
			if not game.party_choice_panel.visible: return false
			game.party_choice_panel._on_left_chosen(); wait = 0.2
		2:
			T = TS.targets.duplicate(); T.sort_custom(func(a, b): return a.index < b.index)
			P("party size %d" % T.size())
			var chain := make("chain", ["DIRECT", "MULTI"], [eff("HealEffect", {"amount": 30.0, "neighbor_amount": 15.0})])
			P("chain text: '%s'" % chain.description_plain())
			setall(10.0); ES.cast(chain, T[1])
			P("chain heal on #1: hp = %s (expect 25, 40, 25, 10…)" % [T.map(func(t): return hp(t))])
			var bind := make("bind", ["DIRECT"], [eff("HealEffect", {"amount": 20.0, "lowest_other_amount": 10.0})])
			setall(30.0); T[3].health_comp.current_health = 5.0
			ES.cast(bind, T[0])
			P("binding: #0=%.0f (50) most injured #3=%.0f (15)" % [hp(T[0]), hp(T[3])])
			var renew := make("renew2", ["HOT"], [eff("HotEffect", {"per_second": 4.0, "duration": 3.0})])
			setall(10.0); ES.cast(renew, T[0]); wait = 3.2; step = 3; return false
		3:
			P("HoT 4/s for 3s: hp=%.0f (expect 22) hot_time=%.1f statuses=%d" % [hp(T[0]), T[0].health_comp.hot_time, T[0].health_comp.statuses.size()])
			var ward := make("ward", ["SHIELD"], [eff("ShieldEffect", {"amount": 20.0, "duration": 1.0, "heal_on_end": 7.0})])
			setall(30.0); ES.cast(ward, T[0]); ES.cast(ward, T[1])
			var r = T[0].health_comp.take_damage(25.0)
			P("ward broken by 25 dmg: absorbed=%.0f dealt=%.0f hp=%.0f (30-5+7=32)" % [r.absorbed, r.dealt, hp(T[0])])
			wait = 1.2; step = 4; return false
		4:
			P("ward faded on #1: hp=%.0f (37) shield=%.0f" % [hp(T[1]), T[1].health_comp.shield_amount])
			var prot := make("prot", [], [eff("ProtectEffect", {"reduction": 0.5, "duration": 5.0})])
			var stop := make("stop", [], [eff("ProtectEffect", {"reduction": 1.0, "duration": 5.0})])
			setall(40.0); ES.cast(prot, T[0]); ES.cast(stop, T[1])
			T[0].health_comp.take_damage(20.0); T[1].health_comp.take_damage(20.0)
			P("protect 50%%: hp=%.0f (30) · time stop: hp=%.0f (40)" % [hp(T[0]), hp(T[1])])
			P("protect text: '%s' / '%s'" % [prot.description_plain(), stop.description_plain()])
			var angel := make("angel", [], [eff("SaveFromDeathEffect", {"duration": 5.0, "heal_amount": 30.0})])
			ES.cast(angel, T[2]); T[2].health_comp.current_health = 10.0
			T[2].health_comp.take_damage(500.0)
			P("guardian angel vs 500 dmg: dead=%s hp=%.0f (31) combo=%s" % [T[2].health_comp.is_dead, hp(T[2]), combos.has("Saved")])
			var bloom := make("bloom", ["DELAYED"], [eff("DelayedHealEffect", {"amount": 25.0, "delay": 1.0})])
			setall(10.0); ES.cast(bloom, T[0]); wait = 1.2; step = 5; return false
		5:
			P("delayed heal after 1s: hp=%.0f (35)" % hp(T[0]))
			var hot := make("hot", ["HOT"], [eff("HotEffect", {"per_second": 1.0, "duration": 2.0})])
			var grow := make("grow", [], [eff("ExtendHotsEffect", {"seconds": 5.0})])
			ES.cast(hot, T[0]); combos.clear(); ES.cast(grow, T[0])
			var fired := combos.duplicate(); combos.clear(); ES.cast(grow, T[1])
			P("overgrowth: hot_time=%.1f (7) combo=%s | on fighter with no HoT combo=%s" % [T[0].health_comp.hot_time, fired, combos])
			P("overgrowth text: '%s'" % grow.description_plain())
			var echo := make("echo", [], [eff("EchoMarkEffect", {"duration": 8.0, "fraction": 0.5, "delay": 1.0})])
			direct = make("direct", ["DIRECT"], [eff("HealEffect", {"amount": 20.0})])
			setall(10.0); combos.clear(); ES.cast(echo, T[3]); ES.cast(direct, T[3])
			P("echo: right after direct heal hp=%.0f (30) combo=%s" % [hp(T[3]), combos])
			wait = 1.2; step = 6; return false
		6:
			P("echo: 1s later hp=%.0f (40)" % hp(T[3]))
			var shield := make("sh", ["SHIELD"], [eff("ShieldEffect", {"amount": 30.0, "duration": 8.0})])
			var surge := make("surge", ["DIRECT"], [eff("ConsumeShieldsEffect", {"ratio": 1.5})])
			setall(10.0); ES.cast(shield, T[0]); T[0].health_comp.take_damage(10.0)
			combos.clear(); ES.cast(surge, T[0])
			P("spirit surge: shield 20 left → hp=%.0f (40) shield=%.0f combo=%s" % [hp(T[0]), T[0].health_comp.shield_amount, combos])
			GM.mana = 10.0; ES.cast(make("chan", [], [eff("ManaEffect", {"amount": 50.0})]), T[0])
			P("mana effect: mana=%.0f (60)" % GM.mana)
			var passive := make("p", [], [], DoubleDirect.new())
			SS.add_spell(passive)
			setall(10.0); ES.cast(direct, T[1]); ES.cast(make("hh", ["HOT"], [eff("HealEffect", {"amount": 10.0})]), T[2])
			P("passive doubles Direct: hp=%.0f (50) · not HoT-tagged: hp=%.0f (20)" % [hp(T[1]), hp(T[2])])
			P("passive slot: is_passive=%s can_cast=%s spellbook=%s" % [passive.is_passive(), SS.can_cast(passive), SS.spells.map(func(s): return s.id)])
			P("tag text bbcode: '%s'" % SpellTags.fill_bb("Extends your {HOT} effects."))
			quit()
	step += 1
	return false
