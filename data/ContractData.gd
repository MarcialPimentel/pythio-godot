@tool
class_name ContractData
extends Resource

@export var contract_name: String = "Unnamed Contract"
@export var flavor_text: String = ""
@export var reward_gold: int = 0
@export var risk_level: int = 1          # 1–5 scale, used for UI color/meter
@export var is_boss: bool = false
@export var round_number: int = 1
@export var unit_templates: Array[UnitTemplate] = []   # the actual party to spawn
