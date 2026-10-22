# autoload/systems/EffectSystem.gd
# The one place spells take effect. A cast runs each of the spell's effects; every heal
# goes through heal() so passives can change it and react to it; statuses report their
# ticks and endings here. Everything is announced on EventBus so UI, combos and future
# systems (keystones, contract modifiers) can listen without touching spell code.
extends Node

## Battlefield rules (resources/rules/*.tres): apply to everyone unless a passive you own
## cancels them. They use the same hooks as passives.
var battlefield_rules: Array[PassiveRule] = []

## Kept for the fighters' floating numbers: effect_type is "heal", "shield", "hot",
## "protect", "delayed" or "mana".
signal effect_applied(effect_type: String, target, value: float, vfx_color: String)


func _ready() -> void:
	var dir := DirAccess.open("res://resources/rules/")
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			var res_name := f.trim_suffix(".remap")
			if res_name.ends_with(".tres"):
				var r = load("res://resources/rules/" + res_name)
				if r is PassiveRule:
					battlefield_rules.append(r)
			f = dir.get_next()
		battlefield_rules.sort_custom(func(a, b): return a.rule_name < b.rule_name)
	GameManager.show_spec_choice.connect(_reset_rules)


## A new run: passives forget their counters and cooldowns.
func _reset_rules() -> void:
	for rule in battlefield_rules:
		rule.reset_state()
	for s in SpellSystem.library:
		if s.passive:
			s.passive.reset_state()


## Rules in force: battlefield rules no passive cancels, then your passives.
func active_rules() -> Array[PassiveRule]:
	var out: Array[PassiveRule] = []
	var mine := SpellSystem.passive_rules()
	for rule in battlefield_rules:
		if not is_rule_cancelled(rule.rule_id, mine):
			out.append(rule)
	out.append_array(mine)
	return out


## The passive (if any) that cancels battlefield rule `rule_id`.
func cancelled_by(rule_id: String) -> SpellData:
	for s in SpellSystem.passives:
		if s.passive and s.passive.negates.has(rule_id):
			return s
	return null


func is_rule_cancelled(rule_id: String, mine: Array = []) -> bool:
	for r in (mine if not mine.is_empty() else SpellSystem.passive_rules()):
		if r.negates.has(rule_id):
			return true
	return false


## Final size of a shield about to be put on `target` (rules and passives can change it).
func shield_amount(target: Node, amount: float, spell: SpellData) -> float:
	var base := amount
	for rule in active_rules():
		amount = rule.modify_shield(amount, target, spell)
	if amount < base - 0.5:
		EventBus.rule_triggered.emit("diminished", target)
	return amount


## Would casting `spell` on `target` right now fire a combo? (Spell buttons glow gold.)
func would_combo(spell: SpellData, target: Node) -> bool:
	var hc := _hc(target)
	if not spell or not hc or hc.is_dead or spell.is_passive():
		return false
	for e in spell.effects:
		if e and e.would_combo(spell, target):
			return true
	for rule in active_rules():
		if rule.would_combo(spell, target):
			return true
	var heals := spell.effects.any(func(e): return e and e.would_heal(spell, target))
	return heals and spell.tags.has(SpellTags.DIRECT) and hc.has_status("ECHO")


## A cast just spent mana: if nothing is affordable now, the pool has run dry.
func mana_spent() -> void:
	var cheapest := INF
	for s in SpellSystem.spells:
		cheapest = minf(cheapest, s.mana_cost if s.mana_cost > 0.0 else INF)
	if cheapest == INF or GameManager.mana >= cheapest:
		return
	for rule in active_rules():
		rule.on_mana_empty()


## Casts `spell` on `target`: runs every effect in order.
func cast(spell: SpellData, target: Node) -> void:
	if not spell or not is_instance_valid(target):
		return
	# "When you cast…" triggers see the fighter as it was before the spell landed.
	for rule in active_rules():
		rule.on_cast(spell, target)
	for e in spell.effects:
		if e:
			e.apply(spell, target)
	EventBus.spell_cast.emit(spell, target)


## Old name, kept so nothing else has to change.
func apply_effect(target, spell: SpellData) -> void:
	cast(spell, target)


# ── Healing ────────────────────────────────────────────

## Heals `target` by `amount` (before passives). opts: "echo" (this heal is an echo),
## "quiet" (no floating number), "no_echo" (can't start an echo). Returns health restored.
func heal(target: Node, amount: float, spell: SpellData = null, tags: Array = [], opts: Dictionary = {}) -> float:
	var hc := _hc(target)
	if not hc or hc.is_dead or amount <= 0.0:
		return 0.0
	for rule in active_rules():
		amount = rule.modify_heal(amount, target, tags, opts)
	var restored := hc.heal(amount)
	var overheal := maxf(0.0, amount - restored)
	if not opts.get("quiet", false):
		effect_applied.emit("heal", target, amount, "")
	EventBus.healed.emit(target, restored, overheal, spell, tags)
	for rule in active_rules():
		rule.on_healed(target, restored, overheal, tags, opts)
	_echo(target, amount, spell, tags, opts)
	return restored


## Direct heals on a fighter with an echo mark repeat part of themselves later.
func _echo(target: Node, amount: float, spell: SpellData, tags: Array, opts: Dictionary) -> void:
	if not tags.has(SpellTags.DIRECT) or opts.get("echo", false) or opts.get("no_echo", false):
		return
	var hc := _hc(target)
	for s in hc.get_statuses("ECHO"):
		var mark := s as EchoStatus
		var echo := DelayedHealStatus.new(amount * mark.fraction, mark.delay, true)
		echo.spell = spell
		echo.tags = tags
		echo.label = "Echo"
		hc.add_status(echo)
		combo(target, "Echo")


# ── Statuses report here ───────────────────────────────

func add_status(target: Node, status: Status, spell: SpellData) -> void:
	var hc := _hc(target)
	if not hc or hc.is_dead:
		return
	status.spell = spell
	if spell:
		status.tags = spell.tags
		if status.label == "":
			status.label = spell.display_name
	hc.add_status(status)


func hot_tick(target: Node, amount: float, status) -> void:
	heal(target, amount, status.spell, status.tags, {"quiet": true, "no_echo": true})
	effect_applied.emit("hot_tick", target, amount, "")
	EventBus.hot_ticked.emit(target, amount, status)
	for rule in active_rules():
		rule.on_hot_tick(target, amount, status)


func shield_absorbed(target: Node, amount: float) -> void:
	EventBus.shield_absorbed.emit(target, amount)


func shield_ended(target: Node, status, broken: bool, remaining: float) -> void:
	EventBus.shield_ended.emit(target, status, broken, remaining)
	for rule in active_rules():
		rule.on_shield_ended(target, status, broken, remaining)


func death_prevented(target: Node, save: SaveStatus) -> void:
	combo(target, "Saved!")
	heal(target, save.heal_amount, save.spell, [], {"no_echo": true})


# ── Combos ─────────────────────────────────────────────

## A synergy fired: gold flash on the fighter and (sometimes) a Pythio quip.
func combo(target: Node, label: String) -> void:
	EventBus.combo_fired.emit(target, label)


## Called by a passive rule when it takes effect.
func passive_fired(rule: PassiveRule) -> void:
	var spell := SpellSystem.passive_for_rule(rule)
	if spell:
		EventBus.passive_triggered.emit(spell)


# ── Helpers for effects ────────────────────────────────

func gain_mana(amount: float) -> void:
	GameManager.mana = minf(GameManager.max_mana, GameManager.mana + amount)
	effect_applied.emit("mana", null, amount, "")


func _hc(target: Node) -> HealthComponent:
	if not is_instance_valid(target) or not ("health_comp" in target):
		return null
	return target.health_comp
