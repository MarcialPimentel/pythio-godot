extends Node
class_name EventBus

signal round_started(round: int)
signal round_ended(success: bool)
signal contract_chosen(contract: ContractData)
signal party_spawned()
signal party_cleared()
signal all_targets_dead()
signal game_over(score: int)

# Helper methods to emit (optional, for consistency)
func emit_round_started(round: int) -> void:
	round_started.emit(round)
