extends CharacterBody3D

@export var creature_path: NodePath

@export var walk_speed: float = 0.4
@export var flee_speed: float = 1.5
@export var acceleration: float = 2.0
@export var gravity: float = 9.8

# Park bounds (adjust if needed)
@export var park_min_x: float = -2.5
@export var park_max_x: float = 2.5
@export var park_min_z: float = -2.5
@export var park_max_z: float = 2.5

# Idle/walk behaviour
enum State { IDLE, WALK, FLEE }
var state: State = State.WALK
var state_timer: float = 0.0

var creature: Node3D = null
var move_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	randomize()
	switch_to_walk()


func _physics_process(delta: float) -> void:
	if creature == null:
		creature = get_node_or_null(creature_path)
		return
	
	var desired_velocity := Vector3.ZERO
	
	if is_seen_by_creature():
		state = State.FLEE
		desired_velocity = flee_from_creature()
	else:
		state_timer -= delta
		
		match state:
			State.IDLE:
				desired_velocity = handle_idle()
			State.WALK:
				desired_velocity = handle_walk(delta)
			State.FLEE:
				# Creature lost sight, so calm back down.
				switch_to_walk()
				desired_velocity = handle_walk(delta)
	
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# LOS REACTION
# ======================
func is_seen_by_creature() -> bool:
	if creature == null:
		return false
	
	# CreatureBrain.gd exposes can_see_player.
	# This is intentionally simple for Phase 2.
	return creature.can_see_player


# ======================
# FLEE
# ======================
func flee_from_creature() -> Vector3:
	var away := global_position - creature.global_position
	away.y = 0.0
	
	if away.length() < 0.05:
		away = Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		)
	
	var edge_push := get_edge_push()
	var final_dir := (away.normalized() + edge_push).normalized()
	
	return final_dir * flee_speed


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
	
	var noise := Vector3(
		randf_range(-0.15, 0.15),
		0.0,
		randf_range(-0.15, 0.15)
	)
	
	var final_dir := (move_direction + edge_push + noise).normalized()
	
	return final_dir * walk_speed


func switch_to_walk() -> void:
	state = State.WALK
	state_timer = randf_range(2.0, 4.0)
	
	move_direction = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()


func switch_to_idle() -> void:
	state = State.IDLE
	state_timer = randf_range(0.8, 1.8)


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
