# autoload/systems/BossDirector.gd
# The Crimson Baron fight. He's your patient: he arrives badly hurt (55%) with two guards, and the
# round plays out in three telegraphed phases (announced with a red banner):
#   1. The wound reopens   — steady bleeding
#   2. Assassins in the rafters — a telegraphed strike on him every few seconds
#   3. The execution       — one long warning, then a huge hit: shield, protect or top him up
# Everything scales up each time he returns (every 5th round). All numbers are settings.
extends Node

@export_group("Arrival")
## The Baron starts the fight at this share of his health ("lies dying").
@export_range(0.1, 1.0) var start_health: float = 0.55
## How many guards come with him.
@export var guards: int = 2

@export_group("Phases (share of the round when each starts)")
@export var phase_2_at: float = 0.40
@export var phase_3_at: float = 0.75

@export_group("Damage (share of the Baron's max health)")
@export var bleed_per_second: float = 0.012
@export var bleed_per_second_phase_3: float = 0.02
@export var assassin_hit: float = 0.09
@export var assassin_every: float = 3.5
@export var assassin_warning: float = 1.5
@export var execution_hit: float = 0.22
@export var execution_warning: float = 3.0
## Each return visit, all of the above hit this much harder (0.15 = +15% per visit).
@export var per_visit: float = 0.15

const PHASES := [
	["The wound reopens", "Keep him bleeding slower than you heal."],
	["Assassins in the rafters", "Strikes are coming for the Baron. Watch for the red rings."],
	["The execution", "One big blow is coming. Shield him, protect him, or top him up."],
]

var boss: Node = null
var phase: int = 0
var _round_length: float = 1.0
var _assassin_timer: float = 0.0
var _execution_done := false


func _ready() -> void:
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_ended.connect(func(_r): boss = null; phase = 0)


func is_active() -> bool:
	return boss != null and is_instance_valid(boss)


func visit_factor() -> float:
	return 1.0 + per_visit * (DifficultySystem.boss_appearance(GameManager.current_round) - 1)


func _on_round_started(_r: int) -> void:
	boss = null
	phase = 0
	_execution_done = false
	for t in TargetSystem.targets:
		if is_instance_valid(t) and t.is_boss:
			boss = t
	if not boss:
		return
	_round_length = maxf(1.0, GameManager.round_time)
	_assassin_timer = assassin_every * 0.5
	boss.health_comp.current_health = boss.health_comp.max_health * start_health
	_enter_phase(1)


## Steady damage on the Baron, per second (TargetSystem asks this instead of the usual dps).
func boss_dps(target: Node) -> float:
	var share := bleed_per_second_phase_3 if phase >= 3 else bleed_per_second
	return target.health_comp.max_health * share * visit_factor()


func _process(delta: float) -> void:
	if not is_active() or not GameManager.in_round or boss.health_comp.is_dead:
		return
	var progress := 1.0 - GameManager.round_time / _round_length
	if phase < 2 and progress >= phase_2_at:
		_enter_phase(2)
	if phase < 3 and progress >= phase_3_at:
		_enter_phase(3)
	if phase == 2:
		_assassin_timer -= delta
		if _assassin_timer <= 0.0:
			_assassin_timer = assassin_every
			_strike(assassin_hit, assassin_warning, "ASSASSIN")
	if phase == 3 and not _execution_done:
		_execution_done = true
		var warn := minf(execution_warning, maxf(0.5, GameManager.round_time - 0.5))
		_strike(execution_hit, warn, "EXECUTION")


func _strike(share: float, warning: float, label: String) -> void:
	TargetSystem.telegraph(boss, boss.health_comp.max_health * share * visit_factor(), warning, label)


func _enter_phase(p: int) -> void:
	phase = p
	EventBus.boss_phase.emit(p, PHASES[p - 1][0], PHASES[p - 1][1])
