extends Node

signal target_selected(target: Node)
signal target_hovered(target: Node)
signal target_died(target: Node)   # null when the mouse leaves a fighter
signal round_started(round: int)
signal round_ended(success: bool)
signal contract_chosen(contract: ContractData)
signal party_spawned()
signal targets_spawned(targets: Array[Node])
signal party_cleared()
signal all_targets_dead()
signal game_over(score: int)
signal spell_cast_requested(spell: SpellData, target: Node)
signal spell_cast_completed(spell: SpellData, target: Node, success: bool)
signal round_begun(round: int)  # emitted when round actually starts after spawn
## A round was survived (round_ended fires for losses too).
signal round_cleared(round: int)
# ── Spells and effects (EffectSystem announces these; combos, passives and UI listen) ──
signal spell_cast(spell: SpellData, target: Node)
## A heal landed: `amount` = health restored, `overheal` = the wasted part.
signal healed(target: Node, amount: float, overheal: float, spell: SpellData, tags: Array)
signal hot_ticked(target: Node, amount: float, status)
signal shield_absorbed(target: Node, amount: float)
## A shield ended: `broken` = used up by damage, otherwise it faded.
signal shield_ended(target: Node, status, broken: bool, remaining: float)
## A synergy fired on a fighter (gold flash + label, e.g. "Echo").
signal combo_fired(target: Node, label: String)
## A passive just took effect (the tray slot pulses).
signal passive_triggered(spell: SpellData)

## A burst is telegraphed on a fighter; it lands in `delay` seconds for `damage`.
signal burst_warned(target: Node, damage: float, delay: float)
## A burst landed: `absorbed` went into the shield, `dealt` hit health.
signal burst_landed(target: Node, absorbed: float, dealt: float)


# Helper methods to emit (optional, for consistency)
func emit_round_started(round: int) -> void:
	round_started.emit(round)
