extends Node3D


@export var interval := 2.0
@export var turn_speed := 2.0

@onready var cube := $Cube

var time_elapsed := 0.0
var current_up_direction := Vector3.UP
var next_up_direction := {
	Vector3.UP: Vector3.RIGHT,
	Vector3.RIGHT: Vector3.DOWN,
	Vector3.DOWN: Vector3.LEFT,
	Vector3.LEFT: Vector3.UP,
}
var print_dir := {
	Vector3.UP: "UP",
	Vector3.RIGHT: "RIGHT",
	Vector3.DOWN: "DOWN",
	Vector3.LEFT: "LEFT",
}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Quit"):
		get_tree().quit(0)


func _process(delta) -> void:
	Util.draw_gizmo(cube.transform, 1.0, 1.0)
	time_elapsed += delta
	
	if time_elapsed >= interval:
		time_elapsed = 0
		var up = next_up_direction[current_up_direction]
		current_up_direction = up
		var back = Vector3.BACK
		var right = up.cross(back)
		cube.global_basis = Basis(right, up, back).orthonormalized()
	
	print_debug(print_dir[current_up_direction], ": ", current_up_direction)
	var turn_axis = Input.get_axis("Turn Right", "Turn Left")
	#turn_axis *= -1 if current_up_direction.dot(Vector3.DOWN) > 0 else 1
	var axis = cube.global_basis.y.normalized()
	var angle = turn_speed * delta * turn_axis
	cube.transform = cube.transform.rotated(axis, angle).orthonormalized()
