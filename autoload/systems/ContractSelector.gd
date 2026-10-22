extends Node

func get_contracts_for_round(round_num: int) -> Array[ContractData]:
	if DifficultySystem.is_boss_round(round_num):
		return [ContractGenerator.generate_boss_contract(round_num)]
	# One party per round: two near-identical contracts were a non-choice (owner, 2026-10-21).
	return [ContractGenerator.generate_contract(round_num)]
