extends Control

@onready var left_button: Button = $ChoicesContainer/LeftParty/LeftVBox/LeftButton
@onready var right_button: Button = $ChoicesContainer/RightParty/RightVBox/RightButton

@onready var left_icon: TextureRect = $ChoicesContainer/LeftParty/LeftVBox/LeftIcon
@onready var right_icon: TextureRect = $ChoicesContainer/RightParty/RightVBox/RightIcon

@onready var left_name: Label = $ChoicesContainer/LeftParty/LeftVBox/LeftName
@onready var right_name: Label = $ChoicesContainer/RightParty/RightVBox/RightName

var presets = GameManager.PARTY_PRESETS

func _ready() -> void:
	left_button.pressed.connect(func(): _choose(0))
	right_button.pressed.connect(func(): _choose(1))
	_update_display()

func _update_display() -> void:
	if presets.size() < 2:
		push_error("Not enough presets")
		return
	
	left_icon.texture = presets[0].icon
	left_name.text = presets[0].display_name

	right_icon.texture = presets[1].icon
	right_name.text = presets[1].display_name

func _choose(choice: int) -> void:
	GameManager.start_round(choice)

func setup(preset_left: PartyPreset, preset_right: PartyPreset) -> void:
	presets = [preset_left, preset_right]
	_update_display()
