@tool
class_name UnitTemplate
extends Resource

@export var display_name: String = "Unit"
@export_enum("LIGHT", "MEDIUM", "HEAVY") var armor_type: String = "LIGHT"
@export var base_max_health: int = 100
@export var is_boss_unit: bool = false
## Which character art/name this fighter uses (see assets/art). Chosen from armor type.
@export_enum("knight", "mercenary", "rogue", "adventurer", "baron") var character: String = "adventurer"
