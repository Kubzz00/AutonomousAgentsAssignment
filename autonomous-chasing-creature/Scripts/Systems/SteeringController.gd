extends Node
class_name SteeringController

static func seek(current_position: Vector3, target_position: Vector3, speed: float) -> Vector3:
	var direction := target_position - current_position
	direction.y = 0.0
	
	if direction.length() < 0.05:
		return Vector3.ZERO
	
	return direction.normalized() * speed


static func flee(current_position: Vector3, threat_position: Vector3, speed: float) -> Vector3:
	var direction := current_position - threat_position
	direction.y = 0.0
	
	if direction.length() < 0.05:
		direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	
	return direction.normalized() * speed
