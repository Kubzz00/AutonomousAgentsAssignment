extends Node3D

@export var creature_scene: PackedScene
@export var player_scene: PackedScene

@export var player_count: int = 5
@export var reset_delay: float = 2.0

@onready var creature_spawn: Marker3D = $SpawnPoints/CreatureSpawn
@onready var spawn_points_root: Node3D = $SpawnPoints

var creature_instance: CharacterBody3D = null
var player_instances: Array[CharacterBody3D] = []

var reset_timer: float = 0.0
var reset_pending: bool = false


func _ready() -> void:
	spawn_agents()


func _process(delta: float) -> void:
	if creature_instance == null:
		return

	if player_instances.is_empty():
		return

	if all_players_caught() and not reset_pending:
		reset_pending = true
		reset_timer = reset_delay
		print("All players caught. Resetting soon...")

	if reset_pending:
		reset_timer -= delta

		if reset_timer <= 0.0:
			reset_agents()


# ======================
# SPAWNING
# ======================
func spawn_agents() -> void:
	if creature_scene == null:
		push_error("Creature scene is not assigned in SpawnManager.")
		return

	if player_scene == null:
		push_error("Player scene is not assigned in SpawnManager.")
		return

	creature_instance = creature_scene.instantiate() as CharacterBody3D
	add_child(creature_instance)
	creature_instance.transform = creature_spawn.transform

	spawn_players()

	if creature_instance.has_method("set_spawn_manager"):
		creature_instance.set_spawn_manager(self)

	update_creature_target()

	print("Creature spawned at: ", creature_instance.position)
	print("Players spawned: ", player_instances.size())


func spawn_players() -> void:
	player_instances.clear()

	var player_spawn_markers: Array[Marker3D] = get_player_spawn_markers()

	if player_spawn_markers.is_empty():
		push_error("No PlayerSpawn markers found under SpawnPoints.")
		return

	for i in range(player_count):
		var player := player_scene.instantiate() as CharacterBody3D

		if player == null:
			push_error("Player scene root must be CharacterBody3D.")
			continue

		add_child(player)

		var spawn_marker: Marker3D = player_spawn_markers[i % player_spawn_markers.size()]
		player.transform = spawn_marker.transform

		player_instances.append(player)

		if player.has_method("set_creature"):
			player.set_creature(creature_instance)
		else:
			player.creature_path = player.get_path_to(creature_instance)


func get_player_spawn_markers() -> Array[Marker3D]:
	var markers: Array[Marker3D] = []

	for child in spawn_points_root.get_children():
		if child is Marker3D and child.name.begins_with("PlayerSpawn"):
			markers.append(child)

	return markers


# ======================
# TARGETING
# ======================
func update_creature_target() -> void:
	if creature_instance == null:
		return

	var target := get_nearest_uncaught_player(creature_instance.global_position)

	if target == null:
		return

	creature_instance.target_path = creature_instance.get_path_to(target)

	if creature_instance.has_method("set_target"):
		creature_instance.set_target(target)


func get_nearest_uncaught_player(from_position: Vector3) -> CharacterBody3D:
	var nearest_player: CharacterBody3D = null
	var nearest_distance: float = INF

	for player in player_instances:
		if player == null:
			continue

		if is_player_caught(player):
			continue

		var distance: float = from_position.distance_to(player.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player = player

	return nearest_player


func is_player_caught(player: Node) -> bool:
	if player == null:
		return true

	if player.get("is_caught") == true:
		return true

	return false


func all_players_caught() -> bool:
	if player_instances.is_empty():
		return false

	for player in player_instances:
		if player == null:
			continue

		if not is_player_caught(player):
			return false

	return true


# Called by CreatureBrain after catching one player.
func on_player_caught() -> void:
	update_creature_target()


# ======================
# RESET
# ======================
func reset_agents() -> void:
	reset_pending = false
	reset_timer = 0.0

	if creature_instance:
		creature_instance.transform = creature_spawn.transform

		if creature_instance.has_method("reset_agent"):
			creature_instance.reset_agent()

	var player_spawn_markers: Array[Marker3D] = get_player_spawn_markers()

	if player_spawn_markers.is_empty():
		push_error("No PlayerSpawn markers found for reset.")
		return

	for i in range(player_instances.size()):
		var player := player_instances[i]

		if player == null:
			continue

		var spawn_marker: Marker3D = player_spawn_markers[i % player_spawn_markers.size()]
		player.transform = spawn_marker.transform

		if player.has_method("reset_agent"):
			player.reset_agent()

		if player.has_method("set_creature"):
			player.set_creature(creature_instance)
		else:
			player.creature_path = player.get_path_to(creature_instance)

	update_creature_target()

	print("All agents reset.")
