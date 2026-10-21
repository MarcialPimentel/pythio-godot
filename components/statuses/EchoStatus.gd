# While it lasts, Direct heals on this fighter repeat part of themselves a moment later.
class_name EchoStatus
extends Status

var fraction: float = 0.5
var delay: float = 2.0

func _init(p_fraction: float = 0.5, p_delay: float = 2.0, p_duration: float = 8.0) -> void:
	kind = "ECHO"
	fraction = p_fraction
	delay = p_delay
	duration = p_duration
	time_left = p_duration
