extends CharacterBody3D

@export var threat_path: NodePath

# Movement tuning
@export var roam_speed: float = 1.0
@export var flee_speed: float = 2.2

@export var flee_range: float = 6.0
@export var arena_limit: float = 4.5
@export var gravity: float = 9.8

var threat: Node3D = null

# Roaming
var roam_target: Vector3 = Vector3.ZERO

# Flee system
var flee_target: Vector3 = Vector3.ZERO
var has_flee_target: bool = false


func _ready():
	randomize()
	pick_new_roam_target()


func _physics_process(delta):
	if threat == null:
		threat = get_node_or_null(threat_path)
		return
	
	var distance = global_position.distance_to(threat.global_position)
	
	# 🔥 DECISION LOGIC
	if distance < flee_range:
		flee()
	else:
		has_flee_target = false
		roam()
	
	apply_gravity(delta)
	move_and_slide()
	clamp_position()
	rotate_to_velocity()


# ======================
# 🟢 FLEE (SMART TARGET)
# ======================
func flee():
	# Pick new flee target if needed
	if not has_flee_target or global_position.distance_to(flee_target) < 1.0:
		pick_flee_target()
	
	var desired = SteeringController.seek(global_position, flee_target, flee_speed)
	velocity.x = desired.x
	velocity.z = desired.z


func pick_flee_target():
	var away_dir = (global_position - threat.global_position).normalized()
	
	var distance = 3.5
	
	var target = global_position + away_dir * distance
	
	# Clamp inside arena
	target.x = clamp(target.x, -arena_limit + 0.8, arena_limit - 0.8)
	target.z = clamp(target.z, -arena_limit + 0.8, arena_limit - 0.8)
	
	flee_target = target
	has_flee_target = true


# ======================
# 🟢 ROAMING
# ======================
func roam():
	if global_position.distance_to(roam_target) < 0.7:
		pick_new_roam_target()
	
	var desired = SteeringController.seek(global_position, roam_target, roam_speed)
	velocity.x = desired.x
	velocity.z = desired.z


func pick_new_roam_target():
	var margin = 1.2
	
	var random_x = randf_range(-arena_limit + margin, arena_limit - margin)
	var random_z = randf_range(-arena_limit + margin, arena_limit - margin)
	
	roam_target = Vector3(random_x, global_position.y, random_z)


# ======================
# 🟢 BOUNDARY CONTROL
# ======================
func clamp_position():
	position.x = clamp(position.x, -arena_limit, arena_limit)
	position.z = clamp(position.z, -arena_limit, arena_limit)


# ======================
# 🟢 GRAVITY
# ======================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


# ======================
# 🟢 ROTATION
# ======================
func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
