class_name PartyPreset
extends Resource

@export var display_name: String
@export var icon: Texture2D
@export var targets: Array[Dictionary]  # [{type: "heavy", count: 2}, ...]
