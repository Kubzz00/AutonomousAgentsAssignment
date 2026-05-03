extends Node3D

@export var creature_scene: PackedScene
@export var player_scene: PackedScene

@onready var creature_spawn = $SpawnPoints/CreatureSpawn
@onready var player_spawn = $SpawnPoints/PlayerSpawn

var creature_instance: CharacterBody3D
var player_instance: CharacterBody3D

func _ready():
	spawn_agents()


func spawn_agents():
	if creature_scene:
		creature_instance = creature_scene.instantiate()
		creature_instance.global_transform = creature_spawn.global_transform
		add_child(creature_instance)
	
	if player_scene:
		player_instance = player_scene.instantiate()
		player_instance.global_transform = player_spawn.global_transform
		add_child(player_instance)
	
	if creature_instance and player_instance:
		var creature_path = creature_instance.get_path()
		var player_path = player_instance.get_path()
		
		creature_instance.target_path = player_path
		player_instance.threat_path = creature_path
