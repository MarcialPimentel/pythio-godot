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
	if choices.size() < 2:
		left_name.text = "ERROR"
		right_name.text = "ERROR"
		return
	
	left_choice = choices[0]
	right_choice = choices[1]
	
	# Left side
	left_name.text = left_choice.contract_name
	if left_gold: left_gold.text = str(left_choice.reward_gold) + " gold"
	if left_flavor: left_flavor.text = left_choice.flavor_text
	
	# Optional: set icon if you have one per contract/armor type later
	# left_icon.texture = load("res://assets/icons/" + left_choice.get_armor_icon() + ".png")
	
	# Right side
	right_name.text = right_choice.contract_name
	if right_gold: right_gold.text = str(right_choice.reward_gold) + " gold"
	if right_flavor: right_flavor.text = right_choice.flavor_text
	
	# Enable buttons
	left_button.disabled = false
	right_button.disabled = false


func _on_left_chosen() -> void:
	emit_signal("contract_chosen", left_choice)


func _on_right_chosen() -> void:
	emit_signal("contract_chosen", right_choice)
