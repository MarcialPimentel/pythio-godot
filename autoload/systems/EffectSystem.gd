# autoload/systems/EffectSystem.gd
# The one place spells take effect. A cast runs each of the spell's effects; every heal
# goes through heal() so passives can change it and react to it; statuses report their
# ticks and endings here. Everything is announced on EventBus so UI, combos and future
# systems (keystones, contract modifiers) can listen without touching spell code.
extends Node

## Kept for the fighters' floating numbers: effect_type is "heal", "shield", "hot",
## "protect", "delayed" or "mana".
signal effect_applied(effect_type: String, target, value: float, vfx_color: String)


## Casts `spell` on `target`: runs every effect in order.
func cast(spell: SpellData, target: Node) -> void:
	if not spell or not is_instance_valid(target):
		return
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
	for rule in SpellSystem.passive_rules():
		amount = rule.modify_heal(amount, target, tags, opts)
	var restored := hc.heal(amount)
	var overheal := maxf(0.0, amount - restored)
	if not opts.get("quiet", false):
		effect_applied.emit("heal", target, amount, "")
	EventBus.healed.emit(target, restored, overheal, spell, tags)
	for rule in SpellSystem.passive_rules():
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
	for rule in SpellSystem.passive_rules():
		rule.on_hot_tick(target, amount, status)


func shield_absorbed(target: Node, amount: float) -> void:
	EventBus.shield_absorbed.emit(target, amount)


func shield_ended(target: Node, status, broken: bool, remaining: float) -> void:
	EventBus.shield_ended.emit(target, status, broken, remaining)
	for rule in SpellSystem.passive_rules():
		rule.on_shield_ended(target, status, broken, remaining)


func death_prevented(target: Node, save: SaveStatus) -> void:
	combo(target, "Saved")
	heal(target, save.heal_amount, save.spell, [], {"no_echo": true})


# ── Combos ─────────────────────────────────────────────

## A synergy fired: gold flash on the fighter and (sometimes) a Pythio quip.
func combo(target: Node, label: String) -> void:
	EventBus.combo_fired.emit(target, label)


# ── Helpers for effects ────────────────────────────────

func gain_mana(amount: float) -> void:
	GameManager.mana = minf(GameManager.max_mana, GameManager.mana + amount)
	effect_applied.emit("mana", null, amount, "")


func _hc(target: Node) -> HealthComponent:
	if not is_instance_valid(target) or not ("health_comp" in target):
		return null
	return target.health_comp
