extends CharacterBody3D

@export var target_path: NodePath

# Movement tuning
@export var walk_speed: float = 0.6
@export var chase_speed: float = 1.5

@export var acceleration: float = 2.5   # 🔥 LOWER = smoother
@export var deceleration: float = 3.0

@export var chase_range: float = 6.0
@export var stop_distance: float = 1.2
@export var arena_limit: float = 4.5
@export var gravity: float = 9.8

var target: Node3D = null

func _physics_process(delta):
	if target == null:
		target = get_node_or_null(target_path)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	var desired_velocity = Vector3.ZERO
	
	# 🔥 SPEED CONTROL
	var current_speed = walk_speed
	
	if distance < chase_range:
		current_speed = chase_speed
	
	# 🔥 MOVE TOWARD PLAYER
	if distance > stop_distance:
		desired_velocity = SteeringController.seek(global_position, target.global_position, current_speed)
	
	# 🔥 SMOOTH MOVEMENT (KEY FIX)
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	
	# 🔥 SLOW DOWN NATURALLY
	if desired_velocity == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	
	apply_gravity(delta)
	move_and_slide()
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
	var flat = Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
