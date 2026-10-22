# resources/spells/passives/TagTriggerRule.gd
# One passive built from settings instead of code (#65):
#   WHEN <event> happens to something tagged <tags> [on a fighter below X% health]
#   DO   <action> to <who>.
# Most passives (and, later, keystones) are a .tres file using this script with different
# numbers. The card text is written from the settings, so it always matches.
class_name TagTriggerRule
extends PassiveRule

@export_group("When")
## HEALED: a heal lands (value = health restored)
## HEAL_BOOST: a heal is about to land (action BOOST makes it bigger)
## HOT_TICK: a heal-over-time ticks (value = the tick)
## OVERHEAL: a heal overheals (value = the overheal)
## SHIELD_BROKEN: damage used up a shield (value = what the shield could absorb)
## SHIELD_BOOST: a shield is about to be put on (action BOOST makes it bigger)
## CAST: you finish casting a spell (value = 0)
## MANA_EMPTY: a cast leaves you too little mana for any spell
@export_enum("HEALED", "HEAL_BOOST", "HOT_TICK", "OVERHEAL", "SHIELD_BROKEN", "SHIELD_BOOST", "CAST", "MANA_EMPTY") var event: String = "HEALED"
## Only when the heal/spell/shield has one of these tags (empty = any).
@export var tags: Array[String] = []
## Only on a fighter below this share of their health (0 = any health).
@export_range(0.0, 1.0) var below_health: float = 0.0
## Only when the event's value is at least this (e.g. overheal of 5+).
@export var min_value: float = 0.0
## Ignore quiet heals (heal-over-time ticks, bandages, other passives' heals).
@export var skip_quiet: bool = false
## Ignore echoes (Echo Healing's repeats).
@export var skip_echo: bool = false
## Fire on every Nth matching event only (0 or 1 = every time).
@export var every_nth: int = 0
## Seconds before it can fire again (0 = no limit).
@export var cooldown: float = 0.0

@export_group("Do")
@export_enum("HEAL", "SHIELD", "MANA", "HOT", "EXTEND_HOTS", "BOOST") var action: String = "HEAL"
@export_enum("TARGET", "NEIGHBORS", "MOST_INJURED", "PARTY") var who: String = "TARGET"
## A flat amount (health, shield, mana, or heal per second for HOT).
@export var amount: float = 0.0
## Plus this share of the event's value (0.3 = 30% of it). For BOOST: +30%.
@export var share: float = 0.0
## Cap on the result (0 = no cap).
@export var max_amount: float = 0.0
## Seconds, for SHIELD, HOT and EXTEND_HOTS.
@export var duration: float = 5.0

@export_group("Show")
## Gold combo text on the fighter when it fires ("" = only the passive's tray slot pulses).
@export var combo_label: String = ""
## Card text written by hand instead of from the settings (use {TAG} markers).
@export_multiline var text_override: String = ""

var _count := 0
var _ready_at := 0.0


# ── Hooks (called by EffectSystem) ─────────────────────

func modify_heal(heal_amount: float, target: Node, heal_tags: Array, opts: Dictionary) -> float:
	if event != "HEAL_BOOST" or action != "BOOST" or not _heal_matches(target, heal_tags, opts, heal_amount):
		return heal_amount
	if not _ready():
		return heal_amount
	_fired(target)
	return heal_amount * (1.0 + share)


func modify_shield(shield_amount: float, target: Node, spell: SpellData) -> float:
	if event != "SHIELD_BOOST" or action != "BOOST":
		return shield_amount
	if not _tags_ok(spell.tags if spell else [SpellTags.SHIELD]) or not _health_ok(target) or not _ready():
		return shield_amount
	_fired(target)
	return shield_amount * (1.0 + share)


func on_healed(target: Node, restored: float, overheal: float, heal_tags: Array, opts: Dictionary) -> void:
	if event == "HEALED" and restored > 0.0 and _heal_matches(target, heal_tags, opts, restored):
		_do(target, restored)
	elif event == "OVERHEAL" and overheal > 0.0 and _heal_matches(target, heal_tags, opts, overheal):
		_do(target, overheal)


func on_hot_tick(target: Node, tick: float, status) -> void:
	if event != "HOT_TICK":
		return
	if not _tags_ok(status.tags if status else [SpellTags.HOT]) or not _health_ok(target) or tick < min_value:
		return
	_do(target, tick)


func on_shield_ended(target: Node, status, broken: bool, _remaining: float) -> void:
	if event != "SHIELD_BROKEN" or not broken:
		return
	if status and status.get_meta("trigger_event", "") == event:
		return   # a shield made by a shield-break trigger doesn't set off another (no chains)
	if not _tags_ok(status.tags if status and not status.tags.is_empty() else [SpellTags.SHIELD]) or not _health_ok(target):
		return
	_do(target, status.total if status is ShieldStatus else 0.0)


func on_cast(spell: SpellData, target: Node) -> void:
	if event != "CAST" or not spell or not _tags_ok(spell.tags) or not _health_ok(target):
		return
	_do(target, 0.0)


func on_mana_empty() -> void:
	if event == "MANA_EMPTY":
		_do(null, 0.0)


## Spell buttons glow gold when this would fire on the hovered fighter.
func would_combo(spell: SpellData, target: Node) -> bool:
	if not spell or not _health_ok(target) or not _tags_ok(spell.tags):
		return false
	if event == "CAST":
		return below_health > 0.0 or not tags.is_empty()
	if event == "HEAL_BOOST" or event == "HEALED":
		return below_health > 0.0 and spell.effects.any(func(e): return e and e.would_heal(spell, target))
	return false


# ── Conditions ─────────────────────────────────────────

func _heal_matches(target: Node, heal_tags: Array, opts: Dictionary, value: float) -> bool:
	if opts.get("trigger_event", "") == event:
		return false   # this kind of trigger never sets itself off
	if skip_quiet and opts.get("quiet", false):
		return false
	if skip_echo and opts.get("echo", false):
		return false
	return value >= min_value and _tags_ok(heal_tags) and _health_ok(target)


func _tags_ok(have: Array) -> bool:
	if tags.is_empty():
		return true
	for t in tags:
		if have.has(t):
			return true
	return false


func _health_ok(target: Node) -> bool:
	if below_health <= 0.0:
		return true
	if not is_instance_valid(target) or not ("health_comp" in target):
		return false
	var hc: HealthComponent = target.health_comp
	return hc.current_health / maxf(1.0, hc.max_health) < below_health


func _ready() -> bool:
	if cooldown > 0.0 and _now() < _ready_at:
		return false
	if every_nth > 1:
		_count += 1
		if _count % every_nth != 0:
			return false
	if cooldown > 0.0:
		_ready_at = _now() + cooldown
	return true


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Forget counters and cooldowns (a new run).
func reset_state() -> void:
	_count = 0
	_ready_at = 0.0


# ── Actions ────────────────────────────────────────────

func _value(event_value: float) -> float:
	var v := amount + share * event_value
	return minf(v, max_amount) if max_amount > 0.0 else v


func _do(target: Node, event_value: float) -> void:
	if not _ready():
		return
	var v := _value(event_value)
	if v <= 0.0 and action != "EXTEND_HOTS":
		return
	var did := false
	if action == "MANA":
		EffectSystem.gain_mana(v)
		did = true
	else:
		for t in _targets(target):
			did = _apply(t, v) or did
	if did:
		_fired(target)


func _targets(target: Node) -> Array:
	match who:
		"NEIGHBORS":
			return TargetSystem.neighbors_of(target) if is_instance_valid(target) else []
		"MOST_INJURED":
			var t = TargetSystem.most_injured()
			return [t] if t else []
		"PARTY":
			return TargetSystem.targets.filter(func(x): return is_instance_valid(x) and not x.health_comp.is_dead)
	return [target] if is_instance_valid(target) and not target.health_comp.is_dead else []


func _apply(t: Node, v: float) -> bool:
	match action:
		"HEAL":
			var restored := EffectSystem.heal(t, v, null, [], {"quiet": true, "no_echo": true, "trigger_event": event})
			if restored > 0.0:
				EffectSystem.effect_applied.emit("hot_tick", t, v, "")
			return restored > 0.0
		"SHIELD":
			var s := ShieldStatus.new(v, duration)
			s.label = _label()
			s.set_meta("trigger_event", event)
			EffectSystem.add_status(t, s, null)
			EffectSystem.effect_applied.emit("shield", t, s.remaining, "")
			return true
		"HOT":
			var h := HotStatus.new(v, duration)
			h.label = _label()
			EffectSystem.add_status(t, h, null)
			h.tags = []   # triggered heals-over-time don't count as yours for other combos
			EffectSystem.effect_applied.emit("hot", t, v * duration, "")
			return true
		"EXTEND_HOTS":
			var hots: Array = t.health_comp.get_statuses("HOT")
			for h in hots:
				h.time_left += duration
			return not hots.is_empty()
	return false


func _fired(target: Node) -> void:
	if combo_label != "" and is_instance_valid(target):
		EffectSystem.combo(target, combo_label)
	EffectSystem.passive_fired(self)


func _label() -> String:
	var s = SpellSystem.passive_for_rule(self)
	return s.display_name if s else (combo_label if combo_label != "" else "Passive")


# ── Card text ──────────────────────────────────────────

func describe() -> String:
	var text := text_override if text_override != "" else _auto_text()
	var cancels := _cancels_text()
	return cancels + text[0].to_lower() + text.substr(1) if cancels != "" and text != "" else cancels + text


func _cancels_text() -> String:
	if negates.is_empty():
		return ""
	var names: Array[String] = []
	for id in negates:
		var n := id.capitalize()
		for r in EffectSystem.battlefield_rules:
			if r.rule_id == id:
				n = r.rule_name
		names.append(n)
	return "Cancels %s: " % " and ".join(names)


func _tag_words(fallback: String = "") -> String:
	var t: Array = tags if not tags.is_empty() else ([fallback] if fallback != "" else [])
	return " or ".join(t.map(func(x): return "{%s}" % x))


func _pct(v: float) -> String:
	return "%d%%" % roundi(v * 100.0)


func _amount_text(of_what: String) -> String:
	var parts: Array[String] = []
	if amount > 0.0:
		parts.append(SpellEffect.n(amount))
	if share > 0.0:
		parts.append("%s of %s" % [_pct(share), of_what])
	var s := " + ".join(parts)
	if max_amount > 0.0:
		s += " (up to %s)" % SpellEffect.n(max_amount)
	return s


func _who_text() -> String:
	match who:
		"NEIGHBORS": return "the fighters on each side"
		"MOST_INJURED": return "your most injured fighter"
		"PARTY": return "every fighter"
	return "that fighter"


func _auto_text() -> String:
	var low := " on a fighter below %s health" % _pct(below_health) if below_health > 0.0 else ""
	var of_what := "it"
	var when := ""
	match event:
		"HEALED":
			when = ("When one of your %s heals lands%s" % [_tag_words(), low]) if not tags.is_empty() else "When one of your heals lands%s" % low
		"HOT_TICK":
			when = "Each time one of your %s effects heals%s" % [_tag_words(SpellTags.HOT), low]
		"OVERHEAL":
			when = "When you overheal a fighter"
			of_what = "the overheal"
		"SHIELD_BROKEN":
			when = "When one of your %s effects breaks%s" % [_tag_words(SpellTags.SHIELD), low]
			of_what = "what it could absorb"
		"CAST":
			when = ("When you cast a %s spell%s" % [_tag_words(), low]) if not tags.is_empty() else "When you cast a spell%s" % low
		"MANA_EMPTY":
			when = "When you run your mana dry"
		"HEAL_BOOST":
			var subject := ("Your %s heals" % _tag_words()) if not tags.is_empty() else "Your heals"
			return "%s%s heal %s more%s." % [subject, low, _pct(share), _limits_text()]
		"SHIELD_BOOST":
			return "Your %s effects%s absorb %s more%s." % [_tag_words(SpellTags.SHIELD), low, _pct(share), _limits_text()]
	var what := ""
	var amt := _amount_text(of_what)
	match action:
		"HEAL":
			what = "%s %s healed for %s" % [_who_text(), "are" if who == "NEIGHBORS" else "is", amt]
		"SHIELD":
			what = "%s %s a {SHIELD} of %s for %ss" % [_who_text(), "gain" if who == "NEIGHBORS" else "gains", amt, SpellEffect.n(duration)]
		"MANA":
			what = "you get %s mana" % amt if share <= 0.0 else "you get %s back as mana" % amt
		"HOT":
			what = "%s %s a {HOT} of %s each second for %ss" % [_who_text(), "gain" if who == "NEIGHBORS" else "gains", amt, SpellEffect.n(duration)]
		"EXTEND_HOTS":
			what = "the {HOT} effects on %s last %ss longer" % [_who_text(), SpellEffect.n(duration)]
	return "%s, %s%s." % [when, what, _limits_text()]


func _limits_text() -> String:
	var s := ""
	if every_nth > 1:
		s += " (every %s time)" % _ordinal(every_nth)
	if cooldown > 0.0:
		s += " (once every %ss)" % SpellEffect.n(cooldown)
	return s


static func _ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return "%d%s" % [n, suffix]
