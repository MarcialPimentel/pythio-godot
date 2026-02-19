extends PanelContainer
class_name Target

@onready var armor_icon: TextureRect = $ArmorIcon
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var shield_bar: ProgressBar = $VBoxContainer/ShieldBar
@onready var health_text: Label = $HealthText

@export var armor_type: String = "heavy"
@export var max_hp: float = 100.0
@export var index: int = 0

var health_comp: HealthComponent
var pending_burst_time: float = 0.0:
	set(value):
		pending_burst_time = value
		_update_visuals()

func _ready() -> void:
	health_comp = HealthComponent.new()
	add_child(health_comp)
	health_comp.max_health = max_hp
	health_comp.current_health = max_hp
	health_comp.health_changed.connect(_update_health_text)
	health_comp.shield_changed.connect(_update_shield_bar)
	_update_armor_icon()
	_update_visuals()
	grab_focus()  # For pressed

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()

signal pressed

func _process(_delta: float) -> void:
	if pending_burst_time > 0:
		var pulse = sin(Time.get_ticks_msec() * 0.015) * 0.3 + 0.7
		modulate = Color(pulse * 1.5, 0.2, 0.2)
	else:
		modulate = Color.WHITE

func _update_armor_icon() -> void:
	# Add your icons: res://icons/heavy.png etc. Placeholder:
	var icons = {
		"heavy": preload("res://resources/icons/harmor.png"),  # Replace
		"medium": preload("res://resources/icons/marmor.png"),
		"light": preload("res://resources/icons/larmor.png")
	}
	armor_icon.texture = icons.get(armor_type, preload("res://icon.svg"))

func _update_health_bar() -> void:
	health_bar.value = (health_comp.current_health / max_hp) * 100

func _update_shield_bar() -> void:
	if health_comp.shield_amount > 0:
		shield_bar.visible = true
		var health_pct = (health_comp.current_health / max_hp) * 100
		shield_bar.value = health_pct + (health_comp.shield_amount / max_hp) * 100
	else:
		shield_bar.visible = false

func _update_health_text() -> void:
	var text = "%d/%d" % [int(health_comp.current_health), int(max_hp)]
	if health_comp.shield_amount > 0:
		text += " +%d" % int(health_comp.shield_amount)
	if health_comp.hot_time > 0:
		text += " (%.1fs)" % health_comp.hot_time
	health_text.text = text
	_update_health_bar()
	_update_shield_bar()

func _update_visuals() -> void:
	_update_health_text()
