extends Node3D

@export var spawn_manager_path: NodePath
@export var label_path: NodePath

var spawn_manager: Node = null
var debug_label: Label3D = null


func _ready() -> void:
	spawn_manager = get_node_or_null(spawn_manager_path)
	debug_label = get_node_or_null(label_path)

	if spawn_manager == null:
		push_warning("DebugOverlay: SpawnManager not found.")

	if debug_label == null:
		push_warning("DebugOverlay: DebugLabel not found.")


func _process(_delta: float) -> void:
	if spawn_manager == null or debug_label == null:
		return

	var creature = spawn_manager.creature_instance
	var players = spawn_manager.player_instances

	if creature == null or players == null or players.is_empty():
		debug_label.text = "Waiting for agents..."
		return

	var creature_state := "UNKNOWN"
	var los_text := "false"
	var caught_text := "false"

	if creature.has_method("get_state_name"):
		creature_state = creature.get_state_name()

	if creature.get("can_see_player") == true:
		los_text = "true"

	if creature.get("has_caught_player") == true:
		caught_text = "true"

	var caught_count := 0
	var total_players := 0
	var player_lines := ""

	for i in range(players.size()):
		var player = players[i]

		if player == null:
			continue

		total_players += 1

		var player_state := "UNKNOWN"

		if player.has_method("get_state_name"):
			player_state = player.get_state_name()

		if player.get("is_caught") == true:
			caught_count += 1

		player_lines += "\nP" + str(i + 1) + ": " + player_state

	debug_label.text = (
		"CREATURE: " + creature_state +
		"\nLOS: " + los_text +
		"\nCAUGHT: " + caught_text +
		"\nPLAYERS: " + str(caught_count) + "/" + str(total_players) + " caught" +
		player_lines
	)
