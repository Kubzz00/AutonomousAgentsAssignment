extends CharacterBody3D

@export var target_path: NodePath

# ======================
# MOVEMENT
# ======================
@export var walk_speed: float = 0.4
@export var chase_speed: float = 1.2
@export var acceleration: float = 1.5
@export var gravity: float = 9.8
@export var stop_distance: float = 0.45

# ======================
# PARK BOUNDS
# ======================
@export var park_min_x: float = -2.5
@export var park_max_x: float = 2.5
@export var park_min_z: float = -2.5
@export var park_max_z: float = 2.5

# ======================
# WANDER / IDLE
# ======================
@export var idle_min_time: float = 0.25
@export var idle_max_time: float = 0.55
@export var walk_min_time: float = 2.0
@export var walk_max_time: float = 4.0

# ======================
# LOS / DEBUG
# ======================
@export var debug_los: bool = true
@export var eye_height: float = 0.2
@export var target_height: float = 0.2
@export var los_collision_mask: int = 1

enum State {
	IDLE,
	WANDER,
	CHASE
}

var state: State = State.WANDER

var target: Node3D = null
var can_see_player: bool = false

var state_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO

@onready var los_debug_line: MeshInstance3D = $LOSDebugLine

var los_mesh := ImmediateMesh.new()
var los_seen_material := StandardMaterial3D.new()
var los_blocked_material := StandardMaterial3D.new()


func _ready() -> void:
	randomize()

	los_seen_material.albedo_color = Color(0.0, 1.0, 0.0, 1.0)
	los_blocked_material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)

	if los_debug_line:
		los_debug_line.mesh = los_mesh

	switch_to_wander()


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_node_or_null(target_path)
		return

	update_los()

	var desired_velocity := Vector3.ZERO

	if can_see_player:
		state = State.CHASE
		desired_velocity = chase_player()
	else:
		match state:
			State.IDLE:
				desired_velocity = handle_idle(delta)
			State.WANDER:
				desired_velocity = handle_wander(delta)
			State.CHASE:
				switch_to_wander()
				desired_velocity = handle_wander(delta)

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

	apply_gravity(delta)
	move_and_slide()

	rotate_to_velocity()

	if debug_los:
		update_los_debug_line()


# ======================
# STATE SWITCHING
# ======================
func switch_to_idle() -> void:
	state = State.IDLE
	state_timer = randf_range(idle_min_time, idle_max_time)


func switch_to_wander() -> void:
	state = State.WANDER
	state_timer = randf_range(walk_min_time, walk_max_time)

	wander_direction = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()

	if wander_direction.length() < 0.05:
		wander_direction = Vector3.FORWARD


# ======================
# IDLE
# ======================
func handle_idle(delta: float) -> Vector3:
	state_timer -= delta

	if state_timer <= 0.0:
		switch_to_wander()

	return Vector3.ZERO


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
# NORMAL WANDER
# ======================
func handle_wander(delta: float) -> Vector3:
	state_timer -= delta

	if state_timer <= 0.0:
		switch_to_idle()
		return Vector3.ZERO

	var edge_push := get_edge_push()
	var obstacle_push := get_obstacle_push()

	var noise := Vector3(
		randf_range(-0.12, 0.12),
		0.0,
		randf_range(-0.12, 0.12)
	)

	var final_dir := wander_direction + edge_push + obstacle_push + noise

	if final_dir.length() < 0.05:
		switch_to_wander()
		return Vector3.ZERO

	wander_direction = final_dir.normalized()

	return wander_direction * walk_speed


# ======================
# EDGE AVOIDANCE
# ======================
func get_edge_push() -> Vector3:
	var push := Vector3.ZERO
	var margin := 0.8

	if global_position.x < park_min_x + margin:
		push.x += 1.0
	elif global_position.x > park_max_x - margin:
		push.x -= 1.0

	if global_position.z < park_min_z + margin:
		push.z += 1.0
	elif global_position.z > park_max_z - margin:
		push.z -= 1.0

	return push


# ======================
# OBSTACLE PUSH
# ======================
func get_obstacle_push() -> Vector3:
	var push := Vector3.ZERO

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)

		if collision == null:
			continue

		var collider := collision.get_collider()

		if collider == null:
			continue

		if collider.name == "Platform":
			continue

		var normal := collision.get_normal()
		normal.y = 0.0

		if normal.length() > 0.05:
			push += normal.normalized() * 1.4

	return push


# ======================
# LOS USING DIRECT PHYSICS RAY
# ======================
func update_los() -> void:
	var start_pos := global_position + Vector3.UP * eye_height
	var end_pos := target.global_position + Vector3.UP * target_height

	var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.collision_mask = los_collision_mask
	query.exclude = [self.get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		can_see_player = false
		return

	var hit_collider = result["collider"]
	can_see_player = hit_collider == target


# ======================
# DEBUG LOS LINE
# ======================
func update_los_debug_line() -> void:
	if los_debug_line == null:
		return

	los_mesh.clear_surfaces()

	var start_global := global_position + Vector3.UP * eye_height
	var end_global := target.global_position + Vector3.UP * target_height

	var query := PhysicsRayQueryParameters3D.create(start_global, end_global)
	query.collision_mask = los_collision_mask
	query.exclude = [self.get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		end_global = result["position"]

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
