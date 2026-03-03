@tool
class_name UnitTemplate
extends Resource

@export var display_name: String = "Unit"
@export_enum("LIGHT", "MEDIUM", "HEAVY") var armor_type: String = "LIGHT"
@export var base_max_health: int = 100
@export var burst_threat: float = 0.0     # 0–1, influences telegraph frequency
@export var is_boss_unit: bool = false
