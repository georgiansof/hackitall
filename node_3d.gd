extends Node3D  # or use MeshInstance3D, etc.

# Rotation speed in radians per second
@export var rotation_speed: Vector3 = Vector3(0, 1, 0)  # Rotate around Y axis

func _process(delta: float) -> void:
	rotate_x(rotation_speed.x * delta)
	rotate_y(rotation_speed.y * delta)
	rotate_z(rotation_speed.z * delta)
