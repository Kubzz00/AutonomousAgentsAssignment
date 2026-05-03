extends CharacterBody3D

@export var threat_path: NodePath

# Movement tuning
@export var roam_speed: float = 1.0
@export var flee_speed: float = 2.5

@export var flee_range: float = 6.0
@export var arena_limit: float = 4.5
@export var gravity: float = 9.8

var threat: Node3D = null
var roam_target: Vector3 = Vector3.ZERO
var choosing_new_target: bool = true

func _ready():
	pick_new_roam_target()


func _physics_process(delta):
	if threat == null:
		threat = get_node_or_null(threat_path)
		return
	
	var distance = global_position.distance_to(threat.global_position)
	
	if distance < flee_range:
		flee()
	else:
		roam()
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# 🔴 FLEE BEHAVIOUR
func flee():
	var desired = SteeringController.flee(global_position, threat.global_position, flee_speed)
	velocity.x = desired.x
	velocity.z = desired.z


# 🟢 SMART ROAM (TARGET-BASED)
func roam():
	if choosing_new_target or global_position.distance_to(roam_target) < 0.5:
		pick_new_roam_target()
	
	var desired = SteeringController.seek(global_position, roam_target, roam_speed)
	velocity.x = desired.x
	velocity.z = desired.z


# 🎯 PICK RANDOM POINT IN ARENA
func pick_new_roam_target():
	choosing_new_target = false
	
	var random_x = randf_range(-arena_limit, arena_limit)
	var random_z = randf_range(-arena_limit, arena_limit)
	
	roam_target = Vector3(random_x, global_position.y, random_z)


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
