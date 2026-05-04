extends Node

@export var agent_path: NodePath
@export var marker_path: NodePath

@export var neutral_color: Color = Color(0.4, 0.8, 1.0, 1.0)
@export var alert_color: Color = Color(1.0, 0.1, 0.1, 1.0)
@export var panic_color: Color = Color(1.0, 0.9, 0.1, 1.0)
@export var caught_color: Color = Color(0.45, 0.45, 0.45, 1.0)
@export var catch_color: Color = Color(0.7, 0.0, 1.0, 1.0)

@export var pulse_speed: float = 5.0
@export var pulse_amount: float = 0.12

var agent: Node = null
var marker: MeshInstance3D = null
var marker_material: StandardMaterial3D = null
var base_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	agent = get_node_or_null(agent_path)
	marker = get_node_or_null(marker_path)

	if agent == null:
		push_warning("StateVisualController: agent not found.")
		return

	if marker == null:
		push_warning("StateVisualController: marker not found.")
		return

	base_scale = marker.scale

	marker_material = StandardMaterial3D.new()
	marker_material.emission_enabled = true
	marker_material.emission_energy_multiplier = 1.2
	marker.material_override = marker_material


func _process(_delta: float) -> void:
	if agent == null or marker == null or marker_material == null:
		return

	if not agent.has_method("get_state_name"):
		return

	var state_name: String = agent.get_state_name()
	var color: Color = get_color_for_state(state_name)

	marker_material.albedo_color = color
	marker_material.emission = color

	apply_pulse(state_name)


func get_color_for_state(state_name: String) -> Color:
	match state_name:
		"CHASE":
			return alert_color
		"FLEE":
			return panic_color
		"CATCH":
			return catch_color
		"CAUGHT":
			return caught_color
		_:
			return neutral_color


func apply_pulse(state_name: String) -> void:
	if state_name == "CHASE" or state_name == "FLEE":
		var pulse := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * pulse_amount
		marker.scale = base_scale * pulse
	else:
		marker.scale = base_scale
