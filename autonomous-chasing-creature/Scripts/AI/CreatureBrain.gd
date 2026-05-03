extends CharacterBody3D

@export var target_path: NodePath

# Movement
@export var walk_speed: float = 0.45
@export var chase_speed: float = 1.15
@export var acceleration: float = 1.8
@export var gravity: float = 9.8
@export var stop_distance: float = 0.45

# Park bounds
# Platform scale is 7x7, so edge is about -3.5 to +3.5.
# Use -3 to +3 as safe playable area inside the bush border.
@export var park_min_x: float = -2.5
@export var park_max_x: float = 2.5
@export var park_min_z: float = -2.5
@export var park_max_z: float = 2.5

# Wander tuning
@export var wander_target_margin: float = 0.25
@export var wander_retarget_min_time: float = 3.0
@export var wander_retarget_max_time: float = 6.0

# LOS/debug
@export var debug_los: bool = true
@export var eye_height: float = 0.45
@export var target_height: float = 0.45

var target: Node3D = null
var can_see_player: bool = false
var current_state: String = "WANDER"

var wander_target: Vector3 = Vector3.ZERO
var wander_retarget_timer: float = 0.0

@onready var raycast: RayCast3D = $RayCast3D
@onready var los_debug_line: MeshInstance3D = $LOSDebugLine

var los_mesh := ImmediateMesh.new()
var los_seen_material := StandardMaterial3D.new()
var los_blocked_material := StandardMaterial3D.new()


func _ready() -> void:
	randomize()

	los_seen_material.albedo_color = Color(0.0, 1.0, 0.0, 1.0)
	los_blocked_material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)

	los_debug_line.mesh = los_mesh

	pick_new_wander_target()


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_node_or_null(target_path)
		return

	update_los()

	var desired_velocity := Vector3.ZERO

	if can_see_player:
		current_state = "CHASE"
		desired_velocity = chase_player()
	else:
		current_state = "WANDER"
		desired_velocity = wander(delta)

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()

	if debug_los:
		update_los_debug_line()


# ======================
# CHASE
# ======================
func chase_player() -> Vector3:
	var distance := global_position.distance_to(target.global_position)

	if distance <= stop_distance:
		return Vector3.ZERO

	var direction := target.global_position - global_position
	direction.y = 0.0

	if direction.length() < 0.05:
		return Vector3.ZERO

	return direction.normalized() * chase_speed


# ======================
# WANDER
# ======================
func wander(delta: float) -> Vector3:
	wander_retarget_timer -= delta

	var distance_to_target := global_position.distance_to(wander_target)

	if distance_to_target < 0.5 or wander_retarget_timer <= 0.0:
		pick_new_wander_target()

	var direction := wander_target - global_position
	direction.y = 0.0

	if direction.length() < 0.05:
		return Vector3.ZERO

	return direction.normalized() * walk_speed


func pick_new_wander_target() -> void:
	var x := randf_range(park_min_x + wander_target_margin, park_max_x - wander_target_margin)
	var z := randf_range(park_min_z + wander_target_margin, park_max_z - wander_target_margin)

	wander_target = Vector3(x, global_position.y, z)
	wander_retarget_timer = randf_range(wander_retarget_min_time, wander_retarget_max_time)


# ======================
# LOS
# ======================
func update_los() -> void:
	var origin := global_position + Vector3.UP * eye_height
	var target_pos := target.global_position + Vector3.UP * target_height

	raycast.global_position = origin
	raycast.target_position = raycast.to_local(target_pos)
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var hit := raycast.get_collider()
		can_see_player = hit == target
	else:
		can_see_player = false


# ======================
# DEBUG LOS LINE
# ======================
func update_los_debug_line() -> void:
	los_mesh.clear_surfaces()

	var start_global := global_position + Vector3.UP * eye_height
	var end_global := target.global_position + Vector3.UP * target_height

	if raycast.is_colliding():
		end_global = raycast.get_collision_point()

	var start_local := los_debug_line.to_local(start_global)
	var end_local := los_debug_line.to_local(end_global)

	los_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	los_mesh.surface_add_vertex(start_local)
	los_mesh.surface_add_vertex(end_local)
	los_mesh.surface_end()

	if can_see_player:
		los_debug_line.material_override = los_seen_material
	else:
		los_debug_line.material_override = los_blocked_material


# ======================
# GRAVITY
# ======================
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


# ======================
# ROTATION
# ======================
func rotate_to_velocity() -> void:
	var flat_velocity := Vector3(velocity.x, 0.0, velocity.z)

	if flat_velocity.length() > 0.1:
		look_at(global_position + flat_velocity, Vector3.UP)
