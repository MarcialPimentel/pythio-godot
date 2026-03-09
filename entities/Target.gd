extends Control

@export var armor_type: String = "heavy"
@export var max_hp: float = 100.0
@export var index: int = 0

@export var pending_burst_time: float = 0.0   # ← add this!

@onready var health_comp: HealthComponent = $HealthComponent  # adjust path to your HealthComponent child

@onready var target_name: Label = $Panel/MarginContainer/Vbox/TargetName  # adjust path
@onready var target_button: Button = $Panel/MarginContainer/TargetButton  # adjust path

@onready var hp_bar: ProgressBar = $Panel/MarginContainer/Vbox/health_bar
@onready var shield_bar: ProgressBar = $Panel/MarginContainer/Vbox/shield_bar


signal target_pressed(target: Node)

func _ready() -> void:
	# Visual feedback for armor type
	if armor_type == "heavy":
		modulate = Color(0.7, 0.7, 1.2)
	elif armor_type == "light":
		modulate = Color(1.2, 0.7, 0.7)
	print("Target ready - type:", armor_type, " hp:", max_hp)

	if target_button:
		target_button.pressed.connect(_on_target_button_pressed)

	if health_comp:
		# Connect signals only once
		if not health_comp.health_changed.is_connected(_update_hp_display):
			health_comp.health_changed.connect(_update_hp_display)
		if not health_comp.shield_changed.is_connected(_update_shield_display):
			health_comp.shield_changed.connect(_update_shield_display)

	if "is_boss_unit" in get_meta_list() and get_meta("is_boss_unit", false):  # or check from template
		scale = Vector2(1.5, 1.5)  # Bigger boss
		modulate = Color(1.0, 0.3, 0.3)  # Reddish tint
		print("Boss unit detected - enhanced visuals")

		# Force initial display using current values
		_update_hp_display(health_comp.current_health)
		_update_shield_display(health_comp.shield_amount)

func _update_hp_display(hp: float) -> void:
	if hp_bar:
		hp_bar.value = hp

func _update_shield_display(amount: float) -> void:
	if shield_bar:
		shield_bar.value = amount
		#shield_bar.visible = amount > 0  # hide when empty

func _initialize_health_bar() -> void:
	# These might still be null at ENTER_TREE — that's normal
	if not health_comp or not hp_bar:
		# Don't warn here — _ready() will handle it
		return

	hp_bar.max_value = health_comp.max_health
	hp_bar.value = health_comp.current_health
	_update_hp_display(health_comp.current_health)

	# Optional: only print in debug builds or when you need it
	# print("HP bar initialized for target %d: max=%.1f current=%.1f" % [index, hp_bar.max_value, hp_bar.value])

func _on_target_button_pressed() -> void:
	# Emit your custom signal and pass 'self' as the target
	EventBus.target_selected.emit(self)

func _process(delta: float) -> void:
	if pending_burst_time > 0:
		pending_burst_time -= delta
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		modulate = Color(1 + pulse, pulse * 0.5, pulse * 0.5)  # red flash
	else:
		modulate = Color.WHITE
