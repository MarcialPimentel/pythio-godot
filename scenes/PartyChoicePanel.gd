# PartyChoicePanel.gd
extends Control

@onready var left_button: Button = $ChoicesContainer/LeftParty/LeftVBox/LeftButton
@onready var right_button: Button = $ChoicesContainer/RightParty/RightVBox/RightButton

@onready var left_icon: TextureRect = $ChoicesContainer/LeftParty/LeftVBox/LeftIcon
@onready var right_icon: TextureRect = $ChoicesContainer/RightParty/RightVBox/RightIcon

@onready var left_name: Label = $ChoicesContainer/LeftParty/LeftVBox/LeftName
@onready var right_name: Label = $ChoicesContainer/RightParty/RightVBox/RightName

var presets: Array[PartyPreset] = []

func _ready() -> void:
	left_button.pressed.connect(_on_left_chosen)
	right_button.pressed.connect(_on_right_chosen)

func setup(preset_left: PartyPreset, preset_right: PartyPreset) -> void:
	presets = [preset_left, preset_right]
	
	if preset_left and preset_left.icon:
		left_icon.texture = preset_left.icon
	if left_name:
		left_name.text = preset_left.display_name if preset_left else "Left Party"
	
	if preset_right and preset_right.icon:
		right_icon.texture = preset_right.icon
	if right_name:
		right_name.text = preset_right.display_name if preset_right else "Right Party"

func _on_left_chosen() -> void:
	_choose(0)

func _on_right_chosen() -> void:
	_choose(1)

func _choose(index: int) -> void:
	if index >= presets.size():
		push_error("Invalid party index")
		return
	
	visible = false
	GameManager.start_round(index)
	print("Chosen party: ", presets[index].display_name)
