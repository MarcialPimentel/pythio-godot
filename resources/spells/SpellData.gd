# resources/spells/SpellData.gd
class_name SpellData
extends Resource

@export var id: String = "flash_heal"
@export var display_name: String = "Flash Heal"
@export var icon: Texture2D
@export var mana_cost: float = 25.0
@export var cast_time: float = 0.3

@export_enum("instant_heal", "hot", "shield", "cleanse", "burst") var effect_type: String = "instant_heal"
@export var effect_value: float = 45.0
@export var effect_duration: float = 0.0

# Noir visual accents
@export_enum("EMERALD_GREEN", "ELECTRIC_BLUE", "GOLDEN_YELLOW", "BLOOD_RED") var vfx_color: String = "EMERALD_GREEN"
@export var particle_intensity: float = 1.0

# Combo & flavor
@export var combo_tags: Array[String] = []
@export var flavor_quip: String = "Just a quick stitch..."