extends Node

signal target_added(target: Node)
signal loss_condition
# Signal to tell Game.gd that a target was clicked
signal target_selected(target: Node)

var targets: Array[Node] = []
var burst_timer: float = 0.0

func spawn_party(preset: PartyPreset) -> void:
	for t in targets:
		t.queue_free()
	targets.clear()
	var index = 0
	for config in preset.targets:
		var armor_type: String = config["type"]
		var count: int = config["count"]
		var max_hp: float = {"heavy": 100.0, "medium": 80.0, "light": 60.0}.get(armor_type, 100.0)
		for _i in count:
			var target = preload("res://entities/Target.tscn").instantiate()
			target.armor_type = armor_type
			target.max_hp = max_hp
			target.index = index
			targets.append(target)
			target_added.emit(target)
			target.health_comp.died.connect(func(): loss_condition.emit())
			target.target_pressed.connect(_on_target_clicked)
			targets.append(target)
			target_added.emit(target)
			index += 1

func apply_spell(spell: Spell, target: Node) -> void:
	var hc = target.health_comp
	match spell.effect_type:
		"instant_heal":
			hc.heal(spell.effect_value)
		"hot":
			var boost_mult = 1.25 if hc.shield_amount > 0 else 1.0  # Synergy!
			hc.apply_hot(spell.effect_value * boost_mult, spell.effect_duration)
		"shield":
			hc.apply_shield(spell.effect_value, spell.effect_duration)

func _on_target_clicked(target: Node) -> void:
	# This is a central place to add logic like playing a sound 
	# or updating a "currently selected" UI element
	print("System received click for target: ", target.index)
	target_selected.emit(target)

func _process(delta: float) -> void:
	if not GameManager.in_round:
		return
	update_all(delta)

func update_all(delta: float) -> void:
	burst_timer += delta
	if burst_timer >= 5.0:
		burst_timer = 0.0
		if targets.size() > 0:
			var random_target = targets[randi() % targets.size()]
			random_target.pending_burst_time = 1.2  # Telegraph + burst

	var base_dps = 3.0 + float(GameManager.current_round) * 0.7
	for target in targets:
		var dps_mult = {"heavy": 0.8, "medium": 1.2, "light": 1.6}.get(target.armor_type, 1.0)
		target.health_comp.take_damage(base_dps * dps_mult * delta)
		target.health_comp.tick_effects(delta)
