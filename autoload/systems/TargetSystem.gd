extends Node

signal target_added(target: Node)
signal all_targets_dead
signal loss_condition
signal target_selected(target: Node)

var targets: Array[Node] = []
var burst_timer: float = 0.0

func _ready() -> void:
	EventBus.target_selected.connect(_on_target_selected)

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
			hc.max_health = template.base_max_health
			hc.current_health = template.base_max_health  # or randf_range(0.4, 0.9) * hc.max_health
		
		target.set_meta("armor_type", template.armor_type)
		target.set_meta("burst_threat", template.burst_threat)
		if template.is_boss_unit:
			target.set_meta("is_boss", true)
		
		target.index = index
		
		# Connect signals
		if target.has_signal("died"):
			target.died.connect(func(): loss_condition.emit())
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
	if dead_target in targets:
		targets.erase(dead_target)
	if targets.is_empty():
		all_targets_dead.emit()
		loss_condition.emit()

func clear_targets() -> void:
	print("TargetSystem.clear_targets() called — current count: ", targets.size())
	for t in targets.duplicate():
		if is_instance_valid(t):
			print("Queue freeing target: ", t.name if "name" in t else t)
			t.queue_free()
	targets.clear()
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
		if targets.size() > 0:
			var random_target = targets[randi() % targets.size()]
			random_target.pending_burst_time = DifficultySystem.burst_telegraph_time
	
	var base_dps = DifficultySystem.get_base_dps(GameManager.current_round)
	for target in targets:
		var dps_mult = DifficultySystem.armor_dps_multipliers.get(target.armor_type, 1.0)
		target.health_comp.take_damage(base_dps * dps_mult * delta)
		target.health_comp.tick_effects(delta)
