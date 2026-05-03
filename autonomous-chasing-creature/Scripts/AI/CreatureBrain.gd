extends CharacterBody3D

@export var target_path: NodePath

@export var walk_speed: float = 1.2
@export var chase_speed: float = 2.0

@export var chase_range: float = 6.0
@export var stop_distance: float = 1.2
@export var arena_limit: float = 4.2
@export var gravity: float = 9.8

var target: Node3D = null
var is_active: bool = false   # 🔥 NEW

func _physics_process(delta):
	# Apply gravity always
	apply_gravity(delta)
	move_and_slide()
	
	# 🔥 WAIT UNTIL LANDED
	if not is_active:
		if is_on_floor():
			is_active = true
		return
	
	# Lazy load target
	if target == null:
		target = get_node_or_null(target_path)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	var current_speed = walk_speed
	if distance < chase_range:
		current_speed = chase_speed
	
	if distance > stop_distance:
		var desired = SteeringController.seek(global_position, target.global_position, current_speed)
		velocity.x = desired.x
		velocity.z = desired.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)
	
	clamp_position()
	rotate_to_velocity()


func clamp_position():
	position.x = clamp(position.x, -arena_limit, arena_limit)
	position.z = clamp(position.z, -arena_limit, arena_limit)


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
