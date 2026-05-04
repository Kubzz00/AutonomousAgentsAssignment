extends Area3D

@export var action_name: String = ""
@export var cooldown_time: float = 0.6
@export var press_scale_multiplier: float = 0.88

var can_press: bool = true
var cooldown_timer: float = 0.0
var original_scale: Vector3 = Vector3.ONE

signal button_pressed(action_name: String)


func _ready() -> void:
	original_scale = scale

	monitoring = true
	monitorable = true

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if can_press:
		return

	cooldown_timer -= delta

	if cooldown_timer <= 0.0:
		can_press = true
		scale = original_scale


func _on_area_entered(area: Area3D) -> void:
	if not can_press:
		return

	if not area.is_in_group("menu_pointer"):
		return

	can_press = false
	cooldown_timer = cooldown_time
	scale = original_scale * press_scale_multiplier

	print("Floating menu button pressed: ", action_name)

	button_pressed.emit(action_name)
