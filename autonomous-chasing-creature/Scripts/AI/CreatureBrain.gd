extends CharacterBody3D

@export var target_path: NodePath

# Movement tuning
@export var walk_speed: float = 1.2
@export var chase_speed: float = 2.0

@export var chase_range: float = 6.0
@export var stop_distance: float = 1.2
@export var gravity: float = 9.8

var target: Node3D = null

func _physics_process(delta):
	# Lazy load
	if target == null:
		target = get_node_or_null(target_path)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	var current_speed = walk_speed
	
	if distance < chase_range:
		current_speed = chase_speed
	
	# Movement
	if distance > stop_distance:
		var desired = SteeringController.seek(global_position, target.global_position, current_speed)
		velocity.x = desired.x
		velocity.z = desired.z
	else:
		# slow down when very close
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
