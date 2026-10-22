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

@export_group("Crimson Baron")
## HP on his first appearance, and how much he gains each time he returns.
@export var boss_base_hp: int = 1200
@export var boss_hp_per_appearance: int = 600

@export_group("Fighters")
## Starting HP by armor type (original design: heavy 100 / medium 75 / light 50).
@export var armor_base_hp := {"HEAVY": 100, "MEDIUM": 75, "LIGHT": 50}
## Extra HP per round after the first (0.1 = +10% each round).
@export var hp_growth_per_round: float = 0.1
## Which characters can appear for each armor type.
@export var armor_characters := {"HEAVY": ["knight"], "MEDIUM": ["mercenary"], "LIGHT": ["rogue", "adventurer"]}
@export var character_names := {"knight": "Heavy Knight", "mercenary": "Desperate Mercenary",
	"rogue": "Cursed Rogue", "adventurer": "Injured Adventurer", "baron": "Crimson Baron"}

@export_group("Flavor Templates")
@export var flavor_prefixes: PackedStringArray = ["Injured ", "Desperate ", "Cursed ", "Mercenary "]
@export var flavor_suffixes: PackedStringArray = ["band", "squad", "caravan", "outpost"]

var rng := RandomNumberGenerator.new()

## What Pythio's handler says when the next party shows up.
const NEXT_PARTY_LINES: PackedStringArray = [
	"Another party needs you. They always do.",
	"We got another invite. Bring bandages.",
	"Time for the next group. Same blood, new faces.",
	"Someone paid in advance. Try to earn it.",
	"Fresh customers. Mostly in one piece.",
]


func _ready() -> void:
	rng.randomize()   # or use a seed for testing: rng.seed = 42


func generate_two_choices(current_round: int) -> Array[ContractData]:
	if DifficultySystem.is_boss_round(current_round):
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
	var hp_mult := 1.0 + hp_growth_per_round * (round_num - 1)
	if hp_budget_multiplier:
		hp_mult *= hp_budget_multiplier.sample(progress)
	
	for i in target_units:
		var template := UnitTemplate.new()
		
		# Armor type (weighted random) decides HP and which character shows up
		template.armor_type = _weighted_random_armor()
		var options: Array = armor_characters.get(template.armor_type, ["adventurer"])
		template.character = options[rng.randi() % options.size()]
		template.display_name = character_names.get(template.character, "Fighter")
		template.base_max_health = roundi(armor_base_hp.get(template.armor_type, 75) * hp_mult)
		
		# Burst threat (increases with round)
		template.burst_threat = burst_frequency_curve.sample(progress) if burst_frequency_curve else 0.1 + 0.08 * (round_num - 1)
		
		contract.unit_templates.append(template)
	
	# ── Metadata ──
	contract.is_boss = false
	contract.contract_name = "%d %s %s" % [target_units, flavor_prefixes[rng.randi() % flavor_prefixes.size()], flavor_suffixes[rng.randi() % flavor_suffixes.size()]]
	contract.flavor_text = NEXT_PARTY_LINES[rng.randi() % NEXT_PARTY_LINES.size()]
	
	# ── Reward & Risk ──
	contract.reward_gold = gold_base_per_round + gold_per_unit * target_units
	contract.risk_level = mini(max_risk, roundi(target_units * risk_per_unit + (round_num - 1) * 0.5))
	
	return contract


func generate_boss_contract(round_num: int) -> ContractData:
	var boss := ContractData.new()
	boss.is_boss = true
	boss.round_number = round_num
	var visit := DifficultySystem.boss_appearance(round_num)
	boss.contract_name = "The Crimson Baron" if visit == 1 else "The Crimson Baron returns (visit %d)" % visit
	boss.flavor_text = ("The Baron lies dying after betrayal. Heal him — or face execution." if visit == 1
		else "He survived. He made enemies. He wants the same healer.")
	boss.reward_gold = 300 + gold_boss_bonus
	
	var boss_unit := UnitTemplate.new()
	boss_unit.display_name = "Crimson Baron"
	boss_unit.character = "baron"
	boss_unit.armor_type = "HEAVY"
	boss_unit.base_max_health = boss_base_hp + boss_hp_per_appearance * (visit - 1)
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
	return "LIGHT"  # fallback (rounding)
