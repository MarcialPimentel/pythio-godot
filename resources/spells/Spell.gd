class_name Spell
extends Resource

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var mana_cost: float
@export var cast_time: float = 0.0  # 0 = instant
@export var effect_type: String  # "instant_heal", "hot", "shield"
@export var effect_value: float
@export var effect_duration: float = 0.0
