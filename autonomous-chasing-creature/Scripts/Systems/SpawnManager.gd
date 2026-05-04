extends Node3D

@export var creature_scene: PackedScene
@export var player_scene: PackedScene

@export var reset_delay: float = 2.0

@onready var creature_spawn: Marker3D = $SpawnPoints/CreatureSpawn
@onready var player_spawn: Marker3D = $SpawnPoints/PlayerSpawn

var creature_instance: CharacterBody3D = null
var player_instance: CharacterBody3D = null

var reset_timer: float = 0.0
var reset_pending: bool = false


func _ready() -> void:
	spawn_agents()


func _process(delta: float) -> void:
	if creature_instance == null or player_instance == null:
		return

	if creature_instance.get("has_caught_player") == true and not reset_pending:
		reset_pending = true
		reset_timer = reset_delay
		print("Catch detected. Resetting soon...")

	if reset_pending:
		reset_timer -= delta

		if reset_timer <= 0.0:
			reset_agents()


func spawn_agents() -> void:
	if creature_scene == null:
		push_error("Creature scene is not assigned in SpawnManager.")
		return

	if player_scene == null:
		push_error("Player scene is not assigned in SpawnManager.")
		return

	creature_instance = creature_scene.instantiate()
	player_instance = player_scene.instantiate()

	add_child(creature_instance)
	add_child(player_instance)

	creature_instance.transform = creature_spawn.transform
	player_instance.transform = player_spawn.transform

	creature_instance.target_path = creature_instance.get_path_to(player_instance)
	player_instance.creature_path = player_instance.get_path_to(creature_instance)

	print("Creature spawned at: ", creature_instance.position)
	print("Player spawned at: ", player_instance.position)


func reset_agents() -> void:
	reset_pending = false
	reset_timer = 0.0

	if creature_instance:
		creature_instance.transform = creature_spawn.transform

		if creature_instance.has_method("reset_agent"):
			creature_instance.reset_agent()

	if player_instance:
		player_instance.transform = player_spawn.transform

		if player_instance.has_method("reset_agent"):
			player_instance.reset_agent()

	if creature_instance and player_instance:
		creature_instance.target_path = creature_instance.get_path_to(player_instance)
		player_instance.creature_path = player_instance.get_path_to(creature_instance)

	print("Agents reset.")
