extends Node3D

@export var creature_scene: PackedScene
@export var player_scene: PackedScene

@onready var creature_spawn = $SpawnPoints/CreatureSpawn
@onready var player_spawn = $SpawnPoints/PlayerSpawn

var creature_instance
var player_instance

func _ready():
	spawn_agents()


func spawn_agents():
	if creature_scene:
		creature_instance = creature_scene.instantiate()
		add_child(creature_instance)
		creature_instance.global_transform = creature_spawn.global_transform
	
	if player_scene:
		player_instance = player_scene.instantiate()
		add_child(player_instance)
		player_instance.global_transform = player_spawn.global_transform
