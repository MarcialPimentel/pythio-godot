extends Node

# ── Tunables (easy to expose & tweak in inspector) ──
@export_group("Weights & Base Values")
@export var armor_weights := {"LIGHT": 0.50, "MEDIUM": 0.35, "HEAVY": 0.15}

@export_group("Crimson Baron")
## HP on his first appearance, and how much he gains each time he returns.
@export var boss_base_hp: int = 1200
@export var boss_hp_per_appearance: int = 600

@export_group("Party size")
## Round 1 party size; one more fighter every `party_growth_every` rounds, up to the cap.
@export var party_start: int = 4
@export var party_growth_every: int = 2
@export var party_max: int = 8

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

func _ready() -> void:
	rng.randomize()   # or use a seed for testing: rng.seed = 42


func generate_contract(round_num: int) -> ContractData:
	var contract := ContractData.new()
	contract.round_number = round_num

	var target_units := party_size(round_num)

	# ── Generate units ──
	contract.unit_templates.clear()
	var hp_mult := 1.0 + hp_growth_per_round * (round_num - 1)

	for i in target_units:
		var template := UnitTemplate.new()

		# Armor type (weighted random) decides HP and which character shows up
		template.armor_type = _weighted_random_armor()
		var options: Array = armor_characters.get(template.armor_type, ["adventurer"])
		template.character = options[rng.randi() % options.size()]
		template.display_name = character_names.get(template.character, "Fighter")
		template.base_max_health = roundi(armor_base_hp.get(template.armor_type, 75) * hp_mult)
		contract.unit_templates.append(template)

	# ── Metadata ──
	contract.is_boss = false
	contract.contract_name = "%d %s %s" % [target_units, flavor_prefixes[rng.randi() % flavor_prefixes.size()], flavor_suffixes[rng.randi() % flavor_suffixes.size()]]
	contract.flavor_text = ""   # no flavour line on the Next party screen (owner, 2026-10-24); the Baron keeps his
	return contract


## 4, 4, 5, 5, 6, 6 … up to 8 (owner, 2026-10-21: one more fighter every 2 rounds).
func party_size(round_num: int) -> int:
	return mini(party_max, party_start + maxi(0, round_num - 1) / maxi(1, party_growth_every))


func generate_boss_contract(round_num: int) -> ContractData:
	var boss := ContractData.new()
	boss.is_boss = true
	boss.round_number = round_num
	var visit := DifficultySystem.boss_appearance(round_num)
	boss.contract_name = "The Crimson Baron" if visit == 1 else "The Crimson Baron returns (visit %d)" % visit
	boss.flavor_text = ("The Baron lies dying after betrayal. Heal him — or face execution." if visit == 1
		else "He survived. He made enemies. He wants the same healer.")

	var boss_unit := UnitTemplate.new()
	boss_unit.display_name = "Crimson Baron"
	boss_unit.character = "baron"
	boss_unit.armor_type = "HEAVY"
	boss_unit.base_max_health = boss_base_hp + boss_hp_per_appearance * (visit - 1)
	boss_unit.is_boss_unit = true

	boss.unit_templates = [boss_unit]
	# His guards: ordinary fighters, so the fight is still triage, not one big health bar.
	var hp_mult := 1.0 + hp_growth_per_round * (round_num - 1)
	for i in BossDirector.guards:
		var g := UnitTemplate.new()
		g.display_name = "Baron's Guard"
		g.character = "knight"
		g.armor_type = "HEAVY"
		g.base_max_health = roundi(armor_base_hp.get("HEAVY", 100) * hp_mult)
		boss.unit_templates.append(g)
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
