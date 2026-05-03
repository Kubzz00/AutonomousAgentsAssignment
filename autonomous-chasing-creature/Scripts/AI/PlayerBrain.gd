extends CharacterBody3D

@export var threat_path: NodePath

@export var roam_speed: float = 1.0
@export var flee_speed: float = 2.2

@export var flee_range: float = 6.0
@export var arena_limit: float = 4.5
@export var gravity: float = 9.8

@export var center_force_strength: float = 1.2   # 🔥 KEY

var threat: Node3D = null
var roam_target: Vector3


func _ready():
	randomize()
	pick_new_roam_target()


func _physics_process(delta):
	if threat == null:
		threat = get_node_or_null(threat_path)
		return
	
	var distance = global_position.distance_to(threat.global_position)
	
	var move_dir = Vector3.ZERO
	
	if distance < flee_range:
		move_dir += get_flee_direction()
	else:
		move_dir += get_roam_direction()
	
	# 🔥 ADD CONTINUOUS CENTER FORCE
	move_dir += get_center_force()
	
	move_dir = move_dir.normalized()
	
	var speed = roam_speed
	if distance < flee_range:
		speed = flee_speed
	
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# 🔴 FLEE DIRECTION
# ======================
func get_flee_direction():
	return (global_position - threat.global_position).normalized()


# ======================
# 🟢 ROAM
# ======================
func get_roam_direction():
	if global_position.distance_to(roam_target) < 1.0:
		pick_new_roam_target()
	
	return (roam_target - global_position).normalized()


func pick_new_roam_target():
	var safe = arena_limit * 0.5   # 🔥 keep targets near center
	
	var x = randf_range(-safe, safe)
	var z = randf_range(-safe, safe)
	
	roam_target = Vector3(x, global_position.y, z)


# ======================
# 🔥 CENTER FORCE (FIX)
# ======================
func get_center_force():
	var to_center = -global_position   # (0,0,0 is center)
	
	var dist = to_center.length()
	
	# stronger force near edges
	var strength = clamp(dist / arena_limit, 0.0, 1.0)
	
	return to_center.normalized() * strength * center_force_strength


# ======================
# 🟢 GRAVITY
# ======================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0


# ======================
# 🟢 ROTATION
# ======================
func rotate_to_velocity():
	var flat = Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.1:
		look_at(global_position + flat, Vector3.UP)
