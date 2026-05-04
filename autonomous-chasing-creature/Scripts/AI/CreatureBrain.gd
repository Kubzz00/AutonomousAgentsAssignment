extends CharacterBody3D

@export var target_path: NodePath

# ======================
# ANIMATION
# ======================
@export var animation_player_path: NodePath
@export var idle_animation: String = "Armature|Idle"
@export var walk_animation: String = "Armature|Walk"
@export var run_animation: String = "Armature|Running_Crawl"
@export var catch_animation: String = "Armature|Attack"

# ======================
# MOVEMENT
# ======================
@export var walk_speed: float = 0.4
@export var chase_speed: float = 1.2
@export var acceleration: float = 1.2
@export var turn_smoothing: float = 2.0
@export var gravity: float = 9.8

# Catching
@export var catch_distance: float = 0.4

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
@export var idle_max_time: float = 0.65
@export var walk_min_time: float = 3.0
@export var walk_max_time: float = 5.5

# ======================
# LOS / DEBUG
# ======================
@export var debug_los: bool = true
@export var eye_height: float = 0.2
@export var target_height: float = 0.2
@export var vision_range: float = 4.0
@export var los_collision_mask: int = 1

enum State {
	IDLE,
	WANDER,
	CHASE,
	CATCH
}

var state: State = State.WANDER

var target: Node3D = null
var animation_player: AnimationPlayer = null

var can_see_player: bool = false
var has_caught_player: bool = false

var state_timer: float = 0.0
var move_direction: Vector3 = Vector3.ZERO
var desired_direction: Vector3 = Vector3.ZERO

var current_animation: String = ""

@onready var los_debug_line: MeshInstance3D = $LOSDebugLine

var los_mesh := ImmediateMesh.new()
var los_seen_material := StandardMaterial3D.new()
var los_blocked_material := StandardMaterial3D.new()


func _ready() -> void:
	randomize()

	animation_player = get_node_or_null(animation_player_path)

	los_seen_material.albedo_color = Color(0.0, 1.0, 0.0, 1.0)
	los_blocked_material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)

	if los_debug_line:
		los_debug_line.mesh = los_mesh

	switch_to_wander()


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_node_or_null(target_path)
		return

	if has_caught_player:
		state = State.CATCH
		play_state_animation()

		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

		apply_gravity(delta)
		move_and_slide()

		if debug_los:
			update_los_debug_line()

		return

	var desired_velocity := Vector3.ZERO

	match state:
		State.IDLE:
			can_see_player = check_forward_los()

			if can_see_player:
				state = State.CHASE
				desired_velocity = chase_player(delta)
			else:
				desired_velocity = handle_idle(delta)

		State.WANDER:
			can_see_player = check_forward_los()

			if can_see_player:
				state = State.CHASE
				desired_velocity = chase_player(delta)
			else:
				desired_velocity = handle_wander(delta)

		State.CHASE:
			can_see_player = check_direct_los_to_player()

			if is_close_enough_to_catch():
				catch_player()
				desired_velocity = Vector3.ZERO
			elif can_see_player:
				desired_velocity = chase_player(delta)
			else:
				switch_to_wander()
				desired_velocity = handle_wander(delta)

		State.CATCH:
			desired_velocity = Vector3.ZERO

	play_state_animation()

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

	apply_gravity(delta)
	move_and_slide()

	rotate_to_velocity()

	if debug_los:
		update_los_debug_line()


# ======================
# ANIMATION
# ======================
func play_state_animation() -> void:
	if animation_player == null:
		return

	var desired_animation := idle_animation

	match state:
		State.IDLE:
			desired_animation = idle_animation
		State.WANDER:
			desired_animation = walk_animation
		State.CHASE:
			desired_animation = run_animation
		State.CATCH:
			desired_animation = catch_animation

	play_animation(desired_animation)


func play_animation(animation_name: String) -> void:
	if animation_player == null:
		return

	if animation_name == "":
		return

	if current_animation == animation_name:
		return

	if not animation_player.has_animation(animation_name):
		push_warning("Creature animation not found: " + animation_name)
		return

	current_animation = animation_name
	animation_player.play(animation_name)


# ======================
# STATE SWITCHING
# ======================
func switch_to_idle() -> void:
	state = State.IDLE
	state_timer = randf_range(idle_min_time, idle_max_time)
	play_state_animation()


func switch_to_wander() -> void:
	state = State.WANDER
	state_timer = randf_range(walk_min_time, walk_max_time)

	desired_direction = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()

	if desired_direction.length() < 0.05:
		desired_direction = Vector3.FORWARD

	if move_direction.length() < 0.05:
		move_direction = desired_direction

	play_state_animation()


# ======================
# IDLE
# ======================
func handle_idle(delta: float) -> Vector3:
	state_timer -= delta

	if state_timer <= 0.0:
		switch_to_wander()

	return Vector3.ZERO


# ======================
# WANDER
# ======================
func handle_wander(delta: float) -> Vector3:
	state_timer -= delta

	if state_timer <= 0.0:
		switch_to_idle()
		return Vector3.ZERO

	var edge_push := get_edge_push()
	var obstacle_push := get_obstacle_push()

	var target_dir := (desired_direction + edge_push + obstacle_push).normalized()

	if target_dir.length() < 0.05:
		switch_to_wander()
		return Vector3.ZERO

	move_direction = move_direction.lerp(target_dir, turn_smoothing * delta)

	if move_direction.length() < 0.05:
		move_direction = target_dir

	move_direction = move_direction.normalized()

	return move_direction * walk_speed


# ======================
# CHASE / CATCH
# ======================
func chase_player(delta: float) -> Vector3:
	var direction := target.global_position - global_position
	direction.y = 0.0

	if direction.length() < 0.05:
		return Vector3.ZERO

	var target_dir := direction.normalized()

	move_direction = move_direction.lerp(target_dir, turn_smoothing * delta)

	if move_direction.length() < 0.05:
		move_direction = target_dir

	move_direction = move_direction.normalized()

	return move_direction * chase_speed


func is_close_enough_to_catch() -> bool:
	var flat_self := Vector3(global_position.x, 0.0, global_position.z)
	var flat_target := Vector3(target.global_position.x, 0.0, target.global_position.z)

	return flat_self.distance_to(flat_target) <= catch_distance


func catch_player() -> void:
	has_caught_player = true
	state = State.CATCH
	velocity = Vector3.ZERO
	play_state_animation()

	if target != null and target.has_method("on_caught"):
		target.on_caught()


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
			push += normal.normalized() * 1.5

	return push


# ======================
# LOS HELPERS
# ======================
func check_forward_los() -> bool:
	var start_pos := global_position + Vector3.UP * eye_height

	var forward_dir := -global_transform.basis.z
	forward_dir.y = 0.0

	if forward_dir.length() < 0.05:
		return false

	forward_dir = forward_dir.normalized()

	var end_pos := start_pos + forward_dir * vision_range

	return ray_hits_player(start_pos, end_pos)


func check_direct_los_to_player() -> bool:
	var start_pos := global_position + Vector3.UP * eye_height
	var end_pos := target.global_position + Vector3.UP * target_height

	return ray_hits_player(start_pos, end_pos)


func ray_hits_player(start_pos: Vector3, end_pos: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.collision_mask = los_collision_mask
	query.exclude = [self.get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return false

	var hit_collider = result["collider"]

	return hit_collider == target


# ======================
# DEBUG LOS LINE
# ======================
func update_los_debug_line() -> void:
	if los_debug_line == null:
		return

	los_mesh.clear_surfaces()

	var start_global := global_position + Vector3.UP * eye_height
	var end_global := start_global

	if state == State.CHASE:
		end_global = target.global_position + Vector3.UP * target_height
	else:
		var forward_dir := -global_transform.basis.z
		forward_dir.y = 0.0

		if forward_dir.length() > 0.05:
			forward_dir = forward_dir.normalized()
			end_global = start_global + forward_dir * vision_range

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
