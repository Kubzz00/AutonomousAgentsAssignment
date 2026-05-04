extends Node3D

# ======================
# BOID SETTINGS
# ======================
@export var move_speed: float = 0.55
@export var turn_speed: float = 2.0

@export var neighbor_radius: float = 1.2
@export var separation_radius: float = 0.45

@export var separation_weight: float = 1.8
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var bounds_weight: float = 3.0

# ======================
# LOCAL PARK BOUNDS
# These are LOCAL to BoidManager / Park
# ======================
@export var park_min_x: float = -2.6
@export var park_max_x: float = 2.6
@export var park_min_z: float = -2.6
@export var park_max_z: float = 2.6
@export var min_y: float = 0.3
@export var max_y: float = 1.0

var velocity: Vector3 = Vector3.ZERO
var boid_manager: Node = null


func setup(manager: Node, start_velocity: Vector3) -> void:
	boid_manager = manager

	if start_velocity.length() < 0.05:
		start_velocity = Vector3.FORWARD

	velocity = start_velocity.normalized() * move_speed


func _ready() -> void:
	if velocity.length() < 0.05:
		velocity = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.2, 0.2),
			randf_range(-1.0, 1.0)
		).normalized() * move_speed


func _process(delta: float) -> void:
	if boid_manager == null:
		return

	var steering: Vector3 = calculate_boids_force()
	var desired_velocity: Vector3 = velocity + steering * delta

	if desired_velocity.length() > 0.05:
		desired_velocity = desired_velocity.normalized() * move_speed

	velocity = velocity.lerp(desired_velocity, turn_speed * delta)

	# IMPORTANT:
	# Move in LOCAL space so boids stay inside BoidManager/Park.
	position += velocity * delta

	clamp_inside_bounds()
	face_velocity()


# ======================
# BOIDS CORE
# ======================
func calculate_boids_force() -> Vector3:
	var separation: Vector3 = Vector3.ZERO
	var alignment: Vector3 = Vector3.ZERO
	var cohesion: Vector3 = Vector3.ZERO

	var neighbor_count: int = 0
	var separation_count: int = 0

	if boid_manager == null or not boid_manager.has_method("get_boids"):
		return Vector3.ZERO

	var all_boids: Array = boid_manager.get_boids()

	for other in all_boids:
		if other == self:
			continue

		if other == null:
			continue

		var other_boid: Node3D = other as Node3D

		if other_boid == null:
			continue

		# IMPORTANT:
		# Use local positions because all boids share the same BoidManager parent.
		var distance: float = position.distance_to(other_boid.position)

		if distance <= 0.001:
			continue

		if distance < neighbor_radius:
			var other_velocity: Vector3 = other.get("velocity")
			alignment += other_velocity
			cohesion += other_boid.position
			neighbor_count += 1

		if distance < separation_radius:
			var away: Vector3 = position - other_boid.position
			separation += away.normalized() / distance
			separation_count += 1

	if neighbor_count > 0:
		alignment = (alignment / float(neighbor_count)).normalized()
		cohesion = ((cohesion / float(neighbor_count)) - position).normalized()

	if separation_count > 0:
		separation = (separation / float(separation_count)).normalized()

	var bounds_force: Vector3 = get_bounds_force()

	var final_force: Vector3 = Vector3.ZERO
	final_force += separation * separation_weight
	final_force += alignment * alignment_weight
	final_force += cohesion * cohesion_weight
	final_force += bounds_force * bounds_weight

	return final_force


# ======================
# BOUNDS
# ======================
func get_bounds_force() -> Vector3:
	var force: Vector3 = Vector3.ZERO
	var margin: float = 0.55

	if position.x < park_min_x + margin:
		force.x += 1.0
	elif position.x > park_max_x - margin:
		force.x -= 1.0

	if position.z < park_min_z + margin:
		force.z += 1.0
	elif position.z > park_max_z - margin:
		force.z -= 1.0

	if position.y < min_y:
		force.y += 1.0
	elif position.y > max_y:
		force.y -= 1.0

	if force.length() < 0.05:
		return Vector3.ZERO

	return force.normalized()


func clamp_inside_bounds() -> void:
	position.x = clamp(position.x, park_min_x, park_max_x)
	position.z = clamp(position.z, park_min_z, park_max_z)
	position.y = clamp(position.y, min_y, max_y)


# ======================
# VISUAL ROTATION
# ======================
func face_velocity() -> void:
	if velocity.length() < 0.05:
		return

	look_at(global_position + velocity, Vector3.UP)
