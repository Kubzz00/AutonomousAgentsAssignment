extends Node3D

@export var enabled := true
@export var rotation_speed_degrees := 5.0

func _process(delta: float) -> void:
	if not enabled:
		return
		
	rotation_degrees.y += rotation_speed_degrees * delta
