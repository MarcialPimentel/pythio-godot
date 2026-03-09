# ui/PartyChoicePanel.gd  (or wherever it's located)
extends Control

@onready var left_button: Button = $ChoicesContainer/LeftParty/LeftVBox/LeftButton
@onready var right_button: Button = $ChoicesContainer/RightParty/RightVBox/RightButton

@onready var left_icon: TextureRect = $ChoicesContainer/LeftParty/LeftVBox/LeftIcon
@onready var right_icon: TextureRect = $ChoicesContainer/RightParty/RightVBox/RightIcon

@onready var left_name: Label = $ChoicesContainer/LeftParty/LeftVBox/LeftName
@onready var right_name: Label = $ChoicesContainer/RightParty/RightVBox/RightName

# Add these for better display (you can add more labels later in Priority 2)
@onready var left_gold: Label = $ChoicesContainer/LeftParty/LeftVBox/LeftGold
@onready var right_gold: Label = $ChoicesContainer/RightParty/RightVBox/RightGold
@onready var left_flavor: Label = $ChoicesContainer/LeftParty/LeftVBox/LeftFlavor   # ← add if you want flavor text visible
@onready var right_flavor: Label = $ChoicesContainer/RightParty/RightVBox/RightFlavor

var left_choice: ContractData
var right_choice: ContractData

signal contract_chosen(contract: ContractData)


func _ready() -> void:
	left_button.pressed.connect(_on_left_chosen)
	right_button.pressed.connect(_on_right_chosen)


func setup_contracts(choices: Array[ContractData]) -> void:
	if choices.is_empty():
		left_name.text = "ERROR - No Contract"
		right_name.text = "ERROR"
		left_button.disabled = true
		right_button.disabled = true
		return
	
	# Always fill left
	left_choice = choices[0]
	left_name.text = left_choice.contract_name
	left_gold.text = str(left_choice.reward_gold) + " gold"
	left_flavor.text = left_choice.flavor_text
	left_button.disabled = false
	
	# Right side only if we have 2+
	if choices.size() >= 2:
		right_choice = choices[1]
		right_name.text = right_choice.contract_name
		right_gold.text = str(right_choice.reward_gold) + " gold"
		right_flavor.text = right_choice.flavor_text
		right_button.disabled = false
	else:
		right_name.text = "No Alternative"
		right_gold.text = "—"
		right_flavor.text = "This is the last contract…"
		right_button.disabled = true
		# Optional: gray out right side
		right_name.modulate = Color(0.7, 0.7, 0.7)
		right_gold.modulate = Color(0.7, 0.7, 0.7)


func _on_left_chosen() -> void:
	emit_signal("contract_chosen", left_choice)


func _on_right_chosen() -> void:
	emit_signal("contract_chosen", right_choice)
