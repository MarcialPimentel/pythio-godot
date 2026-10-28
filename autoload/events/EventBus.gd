extends Node

signal target_selected(target: Node)
signal target_hovered(target: Node)   # null when the mouse leaves a fighter
signal target_died(target: Node)
## A new run begins (new game, or the practice round): every system resets on this.
signal run_started()
signal round_started(round: int)
## The round is over, won or lost (round_cleared fires only for wins).
signal round_ended(round: int)
signal contract_chosen(contract: ContractData)
signal party_spawned()
signal targets_spawned(targets: Array[Node])
signal spell_cast_requested(spell: SpellData, target: Node)
## A round was survived (round_ended fires for losses too).
signal round_cleared(round: int)
# ── Spells and effects (EffectSystem announces these; combos, passives and UI listen) ──
signal spell_cast(spell: SpellData, target: Node)
## A heal landed: `amount` = health restored, `overheal` = the wasted part.
signal healed(target: Node, amount: float, overheal: float, spell: SpellData, tags: Array)
signal hot_ticked(target: Node, amount: float, status)
signal shield_absorbed(target: Node, amount: float)
## Damage that protection (Divine Protection, Time Stop) stopped.
signal damage_prevented(target: Node, amount: float)
## A shield ended: `broken` = used up by damage, otherwise it faded.
signal shield_ended(target: Node, status, broken: bool, remaining: float)
## A synergy fired on a fighter (gold flash + label, e.g. "Echo").
signal combo_fired(target: Node, label: String)
## A battlefield rule bit: "diminished" (shield), "saturated" (fighter), "exhausted" (mana).
signal rule_triggered(kind: String, target: Node)
## A passive just took effect (the tray slot pulses).
signal passive_triggered(spell: SpellData)

## A burst is telegraphed on a fighter; it lands in `delay` seconds for `damage`.
signal burst_warned(target: Node, damage: float, delay: float, label: String)
## The Crimson Baron fight moved to a new phase (1, 2, 3): banner title and a hint.
signal boss_phase(phase: int, title: String, hint: String)
## A burst landed: `absorbed` went into the shield, `dealt` hit health.
signal burst_landed(target: Node, absorbed: float, dealt: float)

# ── Debuffs and Cleanse (Phase F) ──
## A debuff went on (or stacked) on `target`. `status` is the DebuffStatus.
signal debuff_applied(target: Node, status)
## Cleanse removed `count` debuffs from `target` (count 0 = nothing to remove).
signal cleansed(target: Node, count: int, spell: SpellData)
## A fighter fell to Dread's line.
signal dread_struck(target: Node)
