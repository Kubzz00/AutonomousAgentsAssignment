extends CharacterBody3D

@export var target_path: NodePath

@export var walk_speed: float = 0.9
@export var chase_speed: float = 1.5

@export var acceleration: float = 2.5

@export var chase_range: float = 6.0
@export var stop_distance: float = 1.2
@export var gravity: float = 9.8

var target: Node3D = null
var can_see_player: bool = false

@onready var raycast: RayCast3D = $RayCast3D


func _physics_process(delta):
	if target == null:
		target = get_node_or_null(target_path)
		return
	
	update_los()
	
	# 🔥 DEBUG (YOU SHOULD SEE TRUE/FALSE CHANGING)
	print("LOS:", can_see_player)
	
	# Movement stays same for now
	var distance = global_position.distance_to(target.global_position)
	
	var desired_velocity = Vector3.ZERO
	
	var current_speed = walk_speed
	if distance < chase_range:
		current_speed = chase_speed
	
	if distance > stop_distance:
		desired_velocity = SteeringController.seek(global_position, target.global_position, current_speed)
	
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# 🔥 LOS FUNCTION
# ======================
func update_los():
	var origin = global_transform.origin
	var target_pos = target.global_transform.origin
	
	var direction = target_pos - origin
	
	# Aim ray
	raycast.target_position = direction
	
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		
		if hit == target:
			can_see_player = true
		else:
			can_see_player = false
	else:
		can_see_player = false


# ======================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0


func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
