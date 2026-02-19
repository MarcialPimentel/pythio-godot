# target.gd
extends Button   # ← root is Button now

@export var armor_type: String = "heavy"
@export var max_hp: float = 100.0
@export var index: int = 0

@export var pending_burst_time: float = 0.0   # ← add this!

@onready var health_comp: HealthComponent = $HealthComponent  # adjust path to your HealthComponent child
@onready var hp_label: ProgressBar = $VBoxContainer/health_bar  # adjust path


signal target_pressed(target: Node)

func _ready() -> void:
	# Visual feedback for armor type
	if armor_type == "heavy":
		modulate = Color(0.7, 0.7, 1.2)
	elif armor_type == "light":
		modulate = Color(1.2, 0.7, 0.7)
	print("Target ready - type:", armor_type, " hp:", max_hp)
	
	if health_comp:
		health_comp.health_changed.connect(_update_hp_display)
	_update_hp_display(health_comp.current_health)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_pressed.emit(self)
		

func _update_hp_display(hp: float) -> void:
	if hp_label:
		var percent = (hp / max_hp) * 100
		hp_label.text = "%.0f%%" % percent

func _process(delta: float) -> void:
	if pending_burst_time > 0:
		pending_burst_time -= delta
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		modulate = Color(1 + pulse, pulse * 0.5, pulse * 0.5)  # red flash
	else:
		modulate = Color.WHITE
