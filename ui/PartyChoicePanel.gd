# ui/PartyChoicePanel.gd — the Next party screen (who you heal next; Ready / Space).
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
	# Lift the card clear of the build summary above the spell bar, and centre the title.
	$ChoicesContainer.position.y -= 50
	var title: Label = $PartyChoiceText
	title.position.y -= 50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.x -= 300
	title.size.x += 600
	left_button.pressed.connect(func(): if not guarded(): _on_left_chosen())
	right_button.pressed.connect(func(): if not guarded(): _on_right_chosen())


## Clicks and keys are ignored until this time (ms); set each time the screen opens.
var _input_open_at := 0


func guard_input() -> void:
	_input_open_at = Time.get_ticks_msec() + int(DifficultySystem.screen_input_guard * 1000.0)


func guarded() -> bool:
	return Time.get_ticks_msec() < _input_open_at


func _unhandled_input(event: InputEvent) -> void:
	# Space or Enter takes the job (between rounds only; in a round Space is a bandage).
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not left_button.disabled:
		get_viewport().set_input_as_handled()
		if not guarded():
			_on_left_chosen()


func setup_contracts(choices: Array[ContractData]) -> void:
	# One party at a time: a single centred card with a Ready button.
	var single := choices.size() == 1
	$ChoicesContainer.alignment = BoxContainer.ALIGNMENT_CENTER
	$ChoicesContainer/RightParty.visible = not single
	left_button.text = "Ready  (Space)" if single else "Take the job"
	if choices.size() > 0:
		$PartyChoiceText.text = "The Crimson Baron sends for you" if choices[0].is_boss else "Next party"
	if choices.is_empty():
		left_name.text = "ERROR - No Contract"
		right_name.text = "ERROR"
		left_button.disabled = true
		right_button.disabled = true
		return
	
	# Always fill left
	left_choice = choices[0]
	left_name.text = left_choice.contract_name
	left_gold.text = describe(left_choice)
	left_flavor.text = left_choice.flavor_text
	left_flavor.visible = left_choice.flavor_text != ""
	left_button.disabled = false
	
	# Right side only if we have 2+
	if choices.size() >= 2:
		right_choice = choices[1]
		right_name.text = right_choice.contract_name
		right_gold.text = describe(right_choice)
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


## One-line summary of who you'd be healing and how risky it is.
## (Gold rewards are hidden for the MVP; the shop idea comes later.)
func describe(c: ContractData) -> String:
	var counts := {}
	var armor := {}
	for t in c.unit_templates:
		counts[t.display_name] = counts.get(t.display_name, 0) + 1
		armor[t.display_name] = t.armor_type.to_lower()
	var parts: Array[String] = []
	for n in counts:
		parts.append("%d× %s (%s armor)" % [counts[n], n, armor[n]])
	return "\n".join(parts)
