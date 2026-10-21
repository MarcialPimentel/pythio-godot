# Reduces incoming damage (1.0 = takes no damage at all).
class_name ProtectStatus
extends Status

var reduction: float = 0.5

func _init(p_reduction: float = 0.5, p_duration: float = 5.0) -> void:
	kind = "PROTECT"
	reduction = clampf(p_reduction, 0.0, 1.0)
	duration = p_duration
	time_left = p_duration
