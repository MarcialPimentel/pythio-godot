extends Node

func get_contracts_for_round(round_num: int) -> Array[ContractData]:
	if DifficultySystem.is_boss_round(round_num):
		return [ContractGenerator.generate_boss_contract(round_num)]
	else:
		return ContractGenerator.generate_two_choices(round_num)
