extends Node

signal target_selected(target: Node)
signal round_started(round: int)
signal round_ended(success: bool)
signal contract_chosen(contract: ContractData)
signal party_spawned()
signal party_cleared()
signal all_targets_dead()
signal game_over(score: int)
signal spell_cast_requested(spell: Spell, target: Node)
signal spell_cast_completed(spell: Spell, target: Node, success: bool)
signal round_begun(round: int)  # emitted when round actually starts after spawn


# Helper methods to emit (optional, for consistency)
func emit_round_started(round: int) -> void:
	round_started.emit(round)
