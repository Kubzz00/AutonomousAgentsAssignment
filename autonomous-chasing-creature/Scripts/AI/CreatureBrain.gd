extends CharacterBody3D

@export var target_path: NodePath

@export var walk_speed: float = 0.4
@export var chase_speed: float = 1.5
@export var acceleration: float = 1.2
@export var stop_distance: float = 1.0
@export var gravity: float = 9.8

# LOS
var target: Node3D = null
var can_see_player: bool = false

@onready var raycast: RayCast3D = $RayCast3D

# Wander
var wander_direction: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0


func _ready():
	randomize()
	wander_direction = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	).normalized()


func _physics_process(delta):
	if target == null:
		target = get_node_or_null(target_path)
		return
		
	print("TARGET POS:", target.global_position)
	update_los()
	
	var desired_velocity = Vector3.ZERO
	
	if can_see_player:
		desired_velocity = chase_player()
		print("CHASING")
	else:
		desired_velocity = wander(delta)
		print("WANDERING")
	
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# 🔴 CHASE
# ======================
func chase_player():
	var direction = (target.global_position - global_position).normalized()
	return direction * chase_speed


# ======================
# 🟢 WANDER
# ======================
func wander(delta):
	wander_timer -= delta
	
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.5, 3.5)
		
		var random_dir = Vector3(
			randf_range(-1, 1),
			0,
			randf_range(-1, 1)
		).normalized()
		
		wander_direction = (wander_direction * 0.6 + random_dir * 0.4).normalized()
	
	var noise = Vector3(
		randf_range(-0.2, 0.2),
		0,
		randf_range(-0.2, 0.2)
	)
	
	var final_dir = (wander_direction + noise).normalized()
	
	return final_dir * walk_speed


# ======================
# 🔵 LOS
# ======================
func update_los():
	var origin = global_transform.origin
	var target_pos = target.global_transform.origin
	
	var direction = target_pos - origin
	
	raycast.target_position = direction
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		can_see_player = (hit == target)
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
