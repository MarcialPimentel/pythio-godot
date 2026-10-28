# autoload/systems/RunStats.gd
# Counts what happened in a run for the game-over summary and the leaderboard.
# Effective healing = health actually restored (no overheal) + damage absorbed by shields
# + damage prevented by protection. It can't exceed the damage the party took.
extends Node

var restored: float = 0.0
var overheal: float = 0.0
var absorbed: float = 0.0
var prevented: float = 0.0
var combos: int = 0
var casts: int = 0
var bandages: int = 0


func _ready() -> void:
	EventBus.run_started.connect(reset)
	EventBus.healed.connect(func(_t, amount, over, _s, _g): restored += amount; overheal += over)
	EventBus.shield_absorbed.connect(func(_t, amount): absorbed += amount)
	EventBus.damage_prevented.connect(func(_t, amount): prevented += amount)
	EventBus.combo_fired.connect(func(_t, _l): combos += 1)
	EventBus.spell_cast.connect(func(_s, _t): casts += 1)
	BandageSystem.channel_started.connect(func(_t, _d): bandages += 1)


func reset() -> void:
	restored = 0.0; overheal = 0.0; absorbed = 0.0; prevented = 0.0
	combos = 0; casts = 0; bandages = 0


func effective_healing() -> int:
	return roundi(restored + absorbed + prevented)


func mitigated() -> int:
	return roundi(absorbed + prevented)


## Share of all healing that was wasted on full health (0–100).
func overheal_percent() -> int:
	var total := restored + overheal
	return roundi(overheal / total * 100.0) if total > 0.0 else 0


static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
