extends Node3D

@export var creature_scene: PackedScene
@export var player_scene: PackedScene

@onready var creature_spawn: Marker3D = $SpawnPoints/CreatureSpawn
@onready var player_spawn: Marker3D = $SpawnPoints/PlayerSpawn

var creature_instance: CharacterBody3D
var player_instance: CharacterBody3D

func _ready() -> void:
	spawn_agents()


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
	
	# Because SpawnManager is on Park and spawns are inside Park,
	# use LOCAL transforms.
	creature_instance.transform = creature_spawn.transform
	player_instance.transform = player_spawn.transform
	
	# Link after both exist.
	creature_instance.target_path = creature_instance.get_path_to(player_instance)
	player_instance.threat_path = player_instance.get_path_to(creature_instance)
	
	print("Creature spawned at: ", creature_instance.position)
	print("Player spawned at: ", player_instance.position)
