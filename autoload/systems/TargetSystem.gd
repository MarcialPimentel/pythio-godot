extends Node

signal target_added(target: Node)
signal all_targets_dead
signal loss_condition
signal target_selected(target: Node)

var targets: Array[Node] = []
var burst_timer: float = 0.0
## Telegraphed bursts waiting to land: [{target, time_left, damage}]
var pending_bursts: Array[Dictionary] = []

func _ready() -> void:
	EventBus.target_selected.connect(_on_target_selected)
	EventBus.round_ended.connect(func(_r): _cancel_bursts())

func _on_target_selected(target: Node) -> void:
	print("TargetSystem received selection via EventBus: ", target.index if "index" in target else "no index")
	target_selected.emit(target)

func spawn_from_contract(contract: ContractData) -> void:
	clear_targets()
	
	var index := 0
	for template in contract.unit_templates:
		var target = preload("res://entities/Target.tscn").instantiate() as Control
		
		# Apply template data
		var hc = target.get_node("HealthComponent") as HealthComponent
		if hc:
			hc.invulnerable = GameManager.god_mode
			hc.max_health = template.base_max_health
			hc.current_health = template.base_max_health  # or randf_range(0.4, 0.9) * hc.max_health
		
		target.armor_type = template.armor_type
		target.character = template.character
		target.display_name = template.display_name
		target.set_meta("armor_type", template.armor_type)
		target.set_meta("burst_threat", template.burst_threat)
		if template.is_boss_unit:
			target.set_meta("is_boss_unit", true)
		
		target.index = index
		
		# Any fighter dying ends the run
		if hc:
			hc.died.connect(_on_target_died.bind(target))
		if target.has_signal("target_pressed"):
			target.target_pressed.connect(_on_target_clicked)
		
		register_target(target)
		
		index += 1
		
	EventBus.targets_spawned.emit(targets)
	EventBus.party_spawned.emit()
	print("TargetSystem spawned %d units from contract" % contract.unit_templates.size())

func register_target(target: Node) -> void:
	targets.append(target)
	target_added.emit(target)

func _on_target_clicked(target: Node) -> void:
	print("System received click for target: ", target.index)
	target_selected.emit(target)

func _on_target_died(dead_target: Node) -> void:
	if not GameManager.in_round:
		return
	print("%s has fallen" % dead_target.display_name)
	EventBus.target_died.emit(dead_target)
	loss_condition.emit()

func clear_targets() -> void:
	print("TargetSystem.clear_targets() called — current count: ", targets.size())
	for t in targets.duplicate():
		if is_instance_valid(t):
			print("Queue freeing target: ", t.name if "name" in t else t)
			t.queue_free()
	targets.clear()
	pending_bursts.clear()
	burst_timer = 0.0
	print("Targets cleared — count now: ", targets.size())

func _process(delta: float) -> void:
	if not GameManager.in_round:
		return
	update_all(delta)

func update_all(delta: float) -> void:
	targets = targets.filter(is_instance_valid)  # safe guard
	
	burst_timer += delta
	if burst_timer >= DifficultySystem.burst_interval:
		burst_timer = 0.0
		_warn_burst()
	_resolve_bursts(delta)
	
	var base_dps = DifficultySystem.get_base_dps(GameManager.current_round)
	for target in targets:
		var dps_mult = DifficultySystem.armor_dps_multipliers.get(target.armor_type, 1.0)
		target.health_comp.take_damage(base_dps * dps_mult * delta)
		target.health_comp.tick_effects(delta)


# ── Bursts: a red warning, then a big hit (shields absorb it first) ──

func _warn_burst() -> void:
	var busy := pending_bursts.map(func(b): return b.target)
	var candidates := targets.filter(func(t): return not t.health_comp.is_dead and not busy.has(t))
	if candidates.is_empty():
		return
	var target = candidates[randi() % candidates.size()]
	var damage := DifficultySystem.get_burst_damage(GameManager.current_round, target.armor_type, target.is_boss)
	var delay := DifficultySystem.burst_telegraph_time
	pending_bursts.append({"target": target, "time_left": delay, "damage": damage})
	target.pending_burst_time = delay
	EventBus.burst_warned.emit(target, damage, delay)


func _resolve_bursts(delta: float) -> void:
	for burst in pending_bursts.duplicate():
		burst.time_left -= delta
		if burst.time_left > 0.0:
			continue
		pending_bursts.erase(burst)
		var target = burst.target
		if not is_instance_valid(target) or target.health_comp.is_dead:
			continue
		var hit: Dictionary = target.health_comp.take_damage(burst.damage)
		EventBus.burst_landed.emit(target, hit.absorbed + hit.prevented, hit.dealt)


func _cancel_bursts() -> void:
	for burst in pending_bursts:
		if is_instance_valid(burst.target):
			burst.target.pending_burst_time = 0.0
	pending_bursts.clear()
	burst_timer = 0.0


# ── Who's next to whom (the party is one row) ──────────

## Living fighters directly left and right of `target`.
func neighbors_of(target: Node) -> Array:
	var alive := _alive_in_order()
	var i := alive.find(target)
	var out: Array = []
	if i == -1:
		return out
	if i > 0:
		out.append(alive[i - 1])
	if i < alive.size() - 1:
		out.append(alive[i + 1])
	return out


## The living fighter (other than `exclude`) with the lowest share of their health left.
func most_injured(exclude: Node = null) -> Node:
	var best: Node = null
	var best_frac := 2.0
	for t in _alive_in_order():
		if t == exclude:
			continue
		var frac: float = t.health_comp.current_health / maxf(1.0, t.health_comp.max_health)
		if frac < best_frac:
			best_frac = frac
			best = t
	return best


func _alive_in_order() -> Array:
	var alive := targets.filter(func(t): return is_instance_valid(t) and not t.health_comp.is_dead)
	alive.sort_custom(func(a, b): return a.index < b.index)
	return alive
