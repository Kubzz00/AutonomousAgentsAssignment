extends CharacterBody3D

@export var threat_path: NodePath

@export var roam_speed: float = 1.0
@export var flee_speed: float = 2.5

@export var flee_range: float = 6.0
@export var arena_limit: float = 4.2
@export var gravity: float = 9.8

var threat: Node3D = null
var roam_target: Vector3 = Vector3.ZERO
var is_active: bool = false   # 🔥 NEW

func _ready():
	pick_new_roam_target()


func _physics_process(delta):
	# Always apply gravity
	apply_gravity(delta)
	move_and_slide()
	
	# 🔥 WAIT UNTIL LANDED
	if not is_active:
		if is_on_floor():
			is_active = true
		return
	
	if threat == null:
		threat = get_node_or_null(threat_path)
		return
	
	var distance = global_position.distance_to(threat.global_position)
	
	if distance < flee_range:
		flee()
	else:
		roam()
	
	clamp_position()
	rotate_to_velocity()


func flee():
	var desired = SteeringController.flee(global_position, threat.global_position, flee_speed)
	velocity.x = desired.x
	velocity.z = desired.z


func roam():
	if global_position.distance_to(roam_target) < 0.5:
		pick_new_roam_target()
	
	var desired = SteeringController.seek(global_position, roam_target, roam_speed)
	velocity.x = desired.x
	velocity.z = desired.z


func pick_new_roam_target():
	var margin = 0.8
	var random_x = randf_range(-arena_limit + margin, arena_limit - margin)
	var random_z = randf_range(-arena_limit + margin, arena_limit - margin)
	
	roam_target = Vector3(random_x, global_position.y, random_z)


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
