extends CharacterBody3D

@export var speed: float = 1.0
@export var acceleration: float = 2.0
@export var gravity: float = 9.8

# Park bounds (adjust if needed)
@export var park_min_x: float = -2.5
@export var park_max_x: float = 2.5
@export var park_min_z: float = -2.5
@export var park_max_z: float = 2.5

# 🔥 STATES
enum State { IDLE, WALK }
var state = State.WALK

# 🔥 timers
var state_timer: float = 0.0

# 🔥 movement
var move_direction: Vector3 = Vector3.ZERO


func _ready():
	randomize()
	switch_to_walk()


func _physics_process(delta):
	state_timer -= delta
	
	match state:
		State.IDLE:
			handle_idle()
		State.WALK:
			handle_walk(delta)
	
	apply_gravity(delta)
	move_and_slide()
	rotate_to_velocity()


# ======================
# 🔵 IDLE
# ======================
func handle_idle():
	velocity.x = 0
	velocity.z = 0
	
	if state_timer <= 0:
		switch_to_walk()


# ======================
# 🟢 WALK
# ======================
func handle_walk(delta):
	if state_timer <= 0:
		switch_to_idle()
		return
	
	# 🔥 EDGE AVOIDANCE
	var push = Vector3.ZERO
	var margin = 1.5
	
	if global_position.x < park_min_x + margin:
		push.x += 1
	elif global_position.x > park_max_x - margin:
		push.x -= 1
	
	if global_position.z < park_min_z + margin:
		push.z += 1
	elif global_position.z > park_max_z - margin:
		push.z -= 1
	
	# 🔥 slight randomness
	var noise = Vector3(
		randf_range(-0.2, 0.2),
		0,
		randf_range(-0.2, 0.2)
	)
	
	var final_dir = (move_direction + push + noise).normalized()
	var desired_velocity = final_dir * speed
	
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)


# ======================
# 🔁 STATE SWITCHING
# ======================
func switch_to_walk():
	state = State.WALK
	state_timer = randf_range(2.0, 4.0)
	
	move_direction = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	).normalized()


func switch_to_idle():
	state = State.IDLE
	state_timer = randf_range(1.0, 2.5)


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
