extends CharacterBody3D

@export var creature_path: NodePath

# ======================
# ANIMATION
# ======================
@export var animation_player_path: NodePath
@export var idle_animation: String = "CharacterArmature|Idle"
@export var walk_animation: String = "CharacterArmature|Walk"
@export var run_animation: String = "CharacterArmature|Run"
@export var caught_animation: String = "CharacterArmature|Death"

# ======================
# MOVEMENT
# ======================
@export var walk_speed: float = 0.5
@export var flee_speed: float = 1.35
@export var acceleration: float = 1.4
@export var turn_smoothing: float = 2.0
@export var gravity: float = 9.8

# ======================
# PARK BOUNDS
# ======================
@export var park_min_x: float = -2.0
@export var park_max_x: float = 2.0
@export var park_min_z: float = -2.0
@export var park_max_z: float = 2.0

enum State {
	IDLE,
	WALK,
	FLEE,
	CAUGHT
}

var state: State = State.WALK
var state_timer: float = 0.0

var creature: Node3D = null
var animation_player: AnimationPlayer = null

var move_direction: Vector3 = Vector3.ZERO
var desired_direction: Vector3 = Vector3.ZERO

var is_caught: bool = false
var current_animation: String = ""


func _ready() -> void:
	randomize()

	animation_player = get_node_or_null(animation_player_path)

	if animation_player == null:
		push_error("PLAYER: AnimationPlayer not found. Check animation_player_path.")
	else:
		print("PLAYER: AnimationPlayer found: ", animation_player.get_path())
		print("PLAYER animations: ", animation_player.get_animation_list())

	switch_to_walk()


func _physics_process(delta: float) -> void:
	if is_caught:
		state = State.CAUGHT
		play_state_animation()

		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

		apply_gravity(delta)
		move_and_slide()
		return

	if creature == null:
		creature = get_node_or_null(creature_path)
		return

	var desired_velocity := Vector3.ZERO

	if is_seen_by_creature():
		state = State.FLEE
		desired_velocity = flee_from_creature(delta)
	else:
		state_timer -= delta

		match state:
			State.IDLE:
				desired_velocity = handle_idle()
			State.WALK:
				desired_velocity = handle_walk(delta)
			State.FLEE:
				switch_to_walk()
				desired_velocity = handle_walk(delta)
			State.CAUGHT:
				desired_velocity = Vector3.ZERO

	play_state_animation()

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# CALLED BY CREATURE
# ======================
func on_caught() -> void:
	is_caught = true
	state = State.CAUGHT
	velocity = Vector3.ZERO
	play_state_animation()


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
		State.WALK:
			desired_animation = walk_animation
		State.FLEE:
			desired_animation = run_animation
		State.CAUGHT:
			desired_animation = caught_animation

	play_animation(desired_animation)


func play_animation(animation_name: String) -> void:
	if animation_player == null:
		return

	if animation_name == "":
		return

	if current_animation == animation_name:
		return

	if not animation_player.has_animation(animation_name):
		push_warning("PLAYER animation not found: " + animation_name)
		return

	current_animation = animation_name
	animation_player.play(animation_name)


# ======================
# LOS REACTION
# ======================
func is_seen_by_creature() -> bool:
	if creature == null:
		return false

	if creature.get("has_caught_player") == true:
		return false

	return creature.get("can_see_player") == true


# ======================
# FLEE
# ======================
func flee_from_creature(delta: float) -> Vector3:
	var away := global_position - creature.global_position
	away.y = 0.0

	if away.length() < 0.05:
		away = Vector3.FORWARD

	var edge_push := get_edge_push()
	var target_dir := (away.normalized() + edge_push).normalized()

	move_direction = move_direction.lerp(target_dir, turn_smoothing * delta)

	if move_direction.length() < 0.05:
		move_direction = target_dir

	move_direction = move_direction.normalized()

	return move_direction * flee_speed


# ======================
# IDLE
# ======================
func handle_idle() -> Vector3:
	if state_timer <= 0.0:
		switch_to_walk()

	return Vector3.ZERO


# ======================
# WALK / WANDER
# ======================
func handle_walk(delta: float) -> Vector3:
	if state_timer <= 0.0:
		switch_to_idle()
		return Vector3.ZERO

	var edge_push := get_edge_push()
	var target_dir := (desired_direction + edge_push).normalized()

	move_direction = move_direction.lerp(target_dir, turn_smoothing * delta)

	if move_direction.length() < 0.05:
		move_direction = target_dir

	move_direction = move_direction.normalized()

	return move_direction * walk_speed


func switch_to_walk() -> void:
	state = State.WALK
	state_timer = randf_range(3.0, 5.5)

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


func switch_to_idle() -> void:
	state = State.IDLE
	state_timer = randf_range(0.7, 1.5)
	play_state_animation()


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
