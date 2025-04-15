extends CharacterBody3D

@export var acceleration := 20.0
@export var max_speed := 50.0
@export var turn_speed := 3.0
@export var brake_force := 30.0
@export var drift_factor := 0.85
@export var friction := 8.0

func _physics_process(delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("Forward"):
		input_vector.y += 1
	if Input.is_action_pressed("Brake"):
		input_vector.y -= 1
	if Input.is_action_pressed("Turn Left"):
		input_vector.x += 1
	if Input.is_action_pressed("Turn Right"):
		input_vector.x -= 1

	# Get movement direction vectors
	var forward_dir = -transform.basis.z
	var right_dir = transform.basis.x

	# Apply acceleration
	var accel = forward_dir * input_vector.y * acceleration
	velocity += accel * delta

	# Clamp speed
	var horizontal_velocity = velocity
	horizontal_velocity.y = 0
	if horizontal_velocity.length() > max_speed:
		horizontal_velocity = horizontal_velocity.normalized() * max_speed
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

	# Turning
	if horizontal_velocity.length() > 1:
		var turn_angle = input_vector.x * turn_speed * delta
		rotate_y(turn_angle)

	# Drift: dampen lateral (sideways) velocity
	var lateral = right_dir * velocity.dot(right_dir)
	velocity -= lateral * drift_factor * delta

	# Braking
	if Input.is_action_pressed("Brake"):
		velocity = velocity.move_toward(Vector3.ZERO, brake_force * delta)

	# Apply friction when not accelerating
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	move_and_slide() # Uses the built-in `velocity`
