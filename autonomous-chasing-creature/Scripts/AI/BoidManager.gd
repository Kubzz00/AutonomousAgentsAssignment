extends Node3D

# ======================
# BOID SPAWNING
# ======================
@export var boid_count: int = 8
@export var boid_scene: PackedScene
@export var use_generated_boids: bool = true

# ======================
# LOCAL PARK BOUNDS
# These are LOCAL to BoidManager.
# ======================
@export var park_min_x: float = -2.6
@export var park_max_x: float = 2.6
@export var park_min_z: float = -2.6
@export var park_max_z: float = 2.6
@export var min_y: float = 0.3
@export var max_y: float = 1.0

# ======================
# VISUALS
# ======================
@export var boid_size: float = 0.07
@export var boid_color: Color = Color(0.4, 1.0, 0.7, 1.0)
@export var emission_energy: float = 1.8

var boids: Array = []


func _ready() -> void:
	randomize()
	spawn_boids()


func spawn_boids() -> void:
	clear_existing_boids()

	for i in range(boid_count):
		var boid: Node3D = create_boid()
		add_child(boid)

		# IMPORTANT:
		# Spawn using LOCAL position inside BoidManager.
		boid.position = get_random_spawn_position()

		var start_velocity: Vector3 = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.2, 0.2),
			randf_range(-1.0, 1.0)
		)

		if start_velocity.length() < 0.05:
			start_velocity = Vector3.FORWARD

		copy_bounds_to_boid(boid)

		if boid.has_method("setup"):
			boid.setup(self, start_velocity)

		boids.append(boid)


func clear_existing_boids() -> void:
	for boid in boids:
		if boid != null:
			boid.queue_free()

	boids.clear()


func create_boid() -> Node3D:
	if boid_scene != null and not use_generated_boids:
		return boid_scene.instantiate()

	var boid := Node3D.new()
	boid.name = "BoidAgent"

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BoidVisual"

	var sphere := SphereMesh.new()
	sphere.radius = boid_size
	sphere.height = boid_size * 2.0
	mesh_instance.mesh = sphere

	var material := StandardMaterial3D.new()
	material.albedo_color = boid_color
	material.emission_enabled = true
	material.emission = boid_color
	material.emission_energy_multiplier = emission_energy
	mesh_instance.material_override = material

	boid.add_child(mesh_instance)

	var script := load("res://Scripts/AI/BoidAgent.gd")
	boid.set_script(script)

	return boid


func copy_bounds_to_boid(boid: Node) -> void:
	boid.park_min_x = park_min_x
	boid.park_max_x = park_max_x
	boid.park_min_z = park_min_z
	boid.park_max_z = park_max_z
	boid.min_y = min_y
	boid.max_y = max_y


func get_random_spawn_position() -> Vector3:
	return Vector3(
		randf_range(park_min_x + 0.4, park_max_x - 0.4),
		randf_range(min_y, max_y),
		randf_range(park_min_z + 0.4, park_max_z - 0.4)
	)


func get_boids() -> Array:
	return boids
