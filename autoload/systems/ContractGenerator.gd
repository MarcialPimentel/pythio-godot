extends Node

# ── Tunables (easy to expose & tweak in inspector) ──
@export_group("Scaling Curves")
@export var unit_count_curve: Curve       # x=0..1 (round progress), y=units
@export var hp_budget_multiplier: Curve   # per round
@export var burst_frequency_curve: Curve

@export_group("Weights & Base Values")
@export var armor_weights := {"LIGHT": 0.50, "MEDIUM": 0.35, "HEAVY": 0.15}
@export var gold_base_per_round: int = 20
@export var gold_per_unit: int = 8
@export var gold_boss_bonus: int = 80
@export var risk_per_unit: float = 0.25
@export var max_risk: int = 5

@export_group("Flavor Templates")
@export var flavor_prefixes: PackedStringArray = ["Injured ", "Desperate ", "Cursed ", "Mercenary "]
@export var flavor_suffixes: PackedStringArray = ["band", "squad", "caravan", "outpost"]

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()   # or use a seed for testing: rng.seed = 42


func generate_two_choices(current_round: int) -> Array[ContractData]:
	if current_round >= 5:
		return [generate_boss_contract(current_round)]
	return [
		generate_contract(current_round),
		generate_contract(current_round)
	]


func generate_contract(round_num: int) -> ContractData:
	var contract := ContractData.new()
	contract.round_number = round_num
	
	# ── Unit count ──
	var progress := float(round_num - 1) / 4.0   # 0..1 across rounds 1–5
	var target_units := roundi(unit_count_curve.sample(progress) if unit_count_curve else 3 + round_num)
	target_units = clamp(target_units, 2, 8)
	
	# ── Generate units ──
	contract.unit_templates.clear()
	var total_hp_budget := int(100 * target_units * (hp_budget_multiplier.sample(progress) if hp_budget_multiplier else 1.2))
	var remaining_hp := total_hp_budget
	
	for i in target_units:
		var template := UnitTemplate.new()
		
		# Armor type (weighted random)
		template.armor_type = _weighted_random_armor()
		
		# Health (distribute budget, slight variance)
		var hp_share := remaining_hp / float(target_units - i)
		template.base_max_health = roundi(hp_share * randf_range(0.8, 1.2))
		remaining_hp -= template.base_max_health
		
		# Burst threat (increases with round)
		template.burst_threat = burst_frequency_curve.sample(progress) if burst_frequency_curve else 0.1 + 0.08 * (round_num - 1)
		
		contract.unit_templates.append(template)
	
	# ── Metadata ──
	contract.is_boss = false
	contract.contract_name = "%d %s %s" % [target_units, flavor_prefixes[rng.randi() % flavor_prefixes.size()], flavor_suffixes[rng.randi() % flavor_suffixes.size()]]
	contract.flavor_text = "A group of %d wounded fighters needs urgent care. Payment upon survival." % target_units
	
	# ── Reward & Risk ──
	contract.reward_gold = gold_base_per_round + gold_per_unit * target_units
	contract.risk_level = mini(max_risk, roundi(target_units * risk_per_unit + (round_num - 1) * 0.5))
	
	return contract


func generate_boss_contract(round_num: int) -> ContractData:
	var boss := ContractData.new()
	boss.is_boss = true
	boss.round_number = round_num
	boss.contract_name = "FINAL CONTRACT: The Crimson Baron"
	boss.flavor_text = "The Baron lies dying after betrayal. Heal him — or face execution."
	boss.reward_gold = 300 + gold_boss_bonus
	
	var boss_unit := UnitTemplate.new()
	boss_unit.display_name = "Crimson Baron"
	boss_unit.armor_type = "HEAVY"
	boss_unit.base_max_health = 1200 + 200 * (round_num - 5)
	boss_unit.burst_threat = 0.8
	boss_unit.is_boss_unit = true
	
	boss.unit_templates = [boss_unit]
	boss.risk_level = 5
	
	return boss


func _weighted_random_armor() -> String:
	var total_weight: float = 0.0
	for w in armor_weights.values():
		total_weight += w
	
	var roll := rng.randf() * total_weight
	var current := 0.0
	for type in armor_weights:
		current += armor_weights[type]
		if roll <= current:
			return type
	return "LIGHT"  # fallback
