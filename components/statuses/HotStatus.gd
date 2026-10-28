# Heals a fixed amount once per second while it lasts.
class_name HotStatus
extends Status

const TICK := 1.0
var per_second: float = 5.0
var _since_tick: float = 0.0

func _init(p_per_second: float = 5.0, p_duration: float = 8.0) -> void:
	kind = "HOT"
	per_second = p_per_second
	duration = p_duration
	time_left = p_duration

func tick(hc: HealthComponent, delta: float) -> void:
	time_left -= delta
	_since_tick += delta
	# On the last frame, a tick that's due "almost exactly now" still pays out: the two
	# timers round differently, and the last tick must not be lost to that.
	var owed := TICK - (0.001 if time_left <= 0.0 else 0.0)
	while _since_tick >= owed and not hc.is_dead:
		_since_tick = maxf(0.0, _since_tick - TICK)
		EffectSystem.hot_tick(target, per_second * TICK, self)
