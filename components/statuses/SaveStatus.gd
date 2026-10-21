# While it lasts, a killing blow leaves the fighter at 1 health and heals them instead.
class_name SaveStatus
extends Status

var heal_amount: float = 30.0

func _init(p_heal: float = 30.0, p_duration: float = 6.0) -> void:
	kind = "SAVE"
	heal_amount = p_heal
	duration = p_duration
	time_left = p_duration
